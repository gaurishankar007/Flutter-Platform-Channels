import AVFoundation
import Flutter
import UIKit

@main
@objc
class AppDelegate: FlutterAppDelegate, IOSCameraHostApi, FlutterTexture,
AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate
{
    // Add a dedicated queue for camera operations
    private let cameraQueue = DispatchQueue(label: "CameraQueue", qos: .userInitiated)
    // The camera session that manages input and output
    private var captureSession: AVCaptureSession?
    // The input device (camera)
    private var videoDeviceInput: AVCaptureDeviceInput?
    // The audio input device (microphone)
    private var audioDeviceInput: AVCaptureDeviceInput?
    // The latest camera frame as a pixel buffer
    private var previewPixelBuffer: CVPixelBuffer?
    // Thread-safe lock to prevent race conditions when accessing previewPixelBuffer
    // from both the camera capture thread (captureOutput) and Flutter UI thread
    private let bufferLock = NSLock()
    // The video device supported sizes
    private var iosCameraSizes: [IOSCameraSize] = []
    
    // The output for preview video frames
    private var previewVideoOutput: AVCaptureVideoDataOutput?
    // Flutter texture registry for displaying camera preview
    private var textureRegistry: FlutterTextureRegistry?
    // The texture ID used by Flutter to render the camera preview
    private var previewTextureId: Int64?
    
    // Event channel for streaming image buffers
    private var imageStreamChannel: FlutterEventChannel?
    // Event sink for the image stream
    var imageStreamSink: FlutterEventSink?
    // The interval between sending image frames while streaming image
    private var frameSkipInterval: Int64 = 1
    // Total number of camera frames processed
    var frameCount: Int64 = 0
    
    // The output for audio frames
    private var audioDataOutput: AVCaptureAudioDataOutput?
    // Event channel for streaming audio buffers
    private var audioStreamChannel: FlutterEventChannel?
    // Event sink for the audio stream
    var audioStreamSink: FlutterEventSink?
    
    // The output for video recording
    private var movieFileOutput: AVCaptureMovieFileOutput?
    // Video recording state
    private var isRecording = false
    private var startRecordingCompletion: ((Result<Bool, Error>) -> Void)?
    private var stopRecordingCompletion: ((Result<Bool, Error>) -> Void)?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?)
    -> Bool {
        // Get the Flutter view controller
        let controller = window?.rootViewController as! FlutterViewController
        
        // Set up the Pigeon API for camera calls from Dart
        IOSCameraHostApiSetup.setUp(binaryMessenger: controller.binaryMessenger, api: self)
        
        // Set up the event channel for image streaming
        imageStreamChannel = FlutterEventChannel(
            name: "com.platform.channel/image_stream",
            binaryMessenger: controller.binaryMessenger
        )
        imageStreamChannel?.setStreamHandler(ImageStreamHandler(owner: self))
        
        // Set up the event channel for audio streaming
        audioStreamChannel = FlutterEventChannel(
            name: "com.platform.channel/audio_stream",
            binaryMessenger: controller.binaryMessenger
        )
        audioStreamChannel?.setStreamHandler(AudioStreamHandler(owner: self))
        
        // Register other Flutter plugins
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func requestCameraAccess(completion: @escaping (Result<Bool, any Error>) -> Void) {
        let permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch permissionStatus {
        case .authorized:
            completion(.success(true))
        case .denied, .restricted:
            completion(.success(false))
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(.success(granted))
                }
            }
        @unknown default:
            completion(.success(false))
        }
    }
    
    func requestMicrophoneAccess(completion: @escaping (Result<Bool, any Error>) -> Void) {
        let permissionStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch permissionStatus {
        case .authorized:
            completion(.success(true))
        case .denied, .restricted:
            completion(.success(false))
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    completion(.success(granted))
                }
            }
        @unknown default:
            completion(.success(false))
        }
    }

    func openCamera(
        request: IOSCameraRequest,
        completion: @escaping (Result<IOSCameraData, any Error>) -> Void)
    {
        // Check camera permission
        if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
            completion(getFailureResult(message: "Camera permission not granted"))
            return
        }
        // Check microphone permission for video recording
        if AVCaptureDevice.authorizationStatus(for: .audio) != .authorized {
            completion(getFailureResult(message: "Microphone permission not granted"))
            return
        }
        
        // Update image stream frame skip interval
        frameSkipInterval = request.imageStreamFrameSkipInterval
        
        // Get the texture registry
        textureRegistry = self.window?.rootViewController as? FlutterTextureRegistry
        guard let registry = textureRegistry else {
            completion(getFailureResult(message: "Texture registry not available"))
            return
        }
        
        // Create and configure the camera session
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .high
        
        // Select the camera (front or back)
        let position: AVCaptureDevice.Position = (request.cameraIndex == 0) ? .back : .front
        guard
            let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
            let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
            session.canAddInput(videoInput)
        else {
            completion(getFailureResult(message: "No camera device found"))
            return
        }
        session.addInput(videoInput)
        self.videoDeviceInput = videoInput
        
        // Add audio input for video recording
        guard
            let audioDevice = AVCaptureDevice.default(.builtInMicrophone, for: .audio, position: .unspecified),
            let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
            session.canAddInput(audioInput)
        else {
            completion(getFailureResult(message: "No audio device found"))
            return
        }
        session.addInput(audioInput)
        self.audioDeviceInput = audioInput
        
        
        // Update video input sizes with supported fps
        getSupportedVideoInputSizes()
        guard
            // Get the format from the requested video input data
            let format = getSupportedVideoInputFormat(
                width:  request.videoInputSize.width,
                height:  request.videoInputSize.height,
                frameRate: request.videoInputFrameRate
            )
        else {
            completion(getFailureResult(message: "Unsupported resolution or frameRate"))
            return
        }
        do {
            // Update video input format
            try videoDevice.lockForConfiguration()
            videoDevice.activeFormat = format
            videoDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale: Int32(request.videoInputFrameRate))
            videoDevice.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: Int32(request.videoInputFrameRate))
            videoDevice.unlockForConfiguration()
        } catch {
            completion(getFailureResult(message: "Failed to lock camera configuration"))
            return
        }
        
        // Add video output to receive camera frames for previewing the camera
        let previewVideoOutput = AVCaptureVideoDataOutput()
        previewVideoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if session.canAddOutput(previewVideoOutput) {
            session.addOutput(previewVideoOutput)
            self.previewVideoOutput = previewVideoOutput
        }
        
        // Add audio output to receive audio frames for streaming
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "audioQueue"))
        if session.canAddOutput(audioOutput) {
            session.addOutput(audioOutput)
            self.audioDataOutput = audioOutput
        }
        
        // Add movie file output for video recording
        let movieOutput = AVCaptureMovieFileOutput()
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
            self.movieFileOutput = movieOutput
        }
        
        session.commitConfiguration()
        self.captureSession = session
        rotateVideoOutput()
        
        // Start the session in background thread
        cameraQueue.async {
            session.startRunning()
            
            // Move Flutter-specific operations to main thread
            DispatchQueue.main.async {
                // Register a Flutter texture for preview
                if let registry = self.textureRegistry {
                    let textureId = registry.register(self)
                    self.previewTextureId = Int64(textureId)
                }
                
                // Prepare the response for Flutter with preview size and texture ID
                let iosCameraData = IOSCameraData(
                    textureId: self.previewTextureId ?? 0,
                    videoInputSize: IOSSize(
                        width: Double(videoDevice.activeFormat.formatDescription.dimensions.width),
                        height: Double(videoDevice.activeFormat.formatDescription.dimensions.height)
                    ),
                    videoInputFrameRate: Int64(videoDevice.activeFormat.videoSupportedFrameRateRanges.first?.maxFrameRate ?? 0),
                    supportedSizes: self.iosCameraSizes,
                )
                completion(.success(iosCameraData))
            }
        }
    }

    func updateCameraVideoOutputOrientation(completion: @escaping (Result<Bool, any Error>) -> Void) {
        rotateVideoOutput()
        completion(.success(true))
    }
        
    func startVideoRecording(completion: @escaping (Result<Bool, any Error>) -> Void) {
        guard let movieOutput = movieFileOutput else {
            completion(getFailureResult(message: "Movie output not available"))
            return
        }
        guard !isRecording else {
            completion(getFailureResult(message: "Already recording"))
            return
        }
        
        // Store completion for when recording actually starts
        startRecordingCompletion = completion
        
        // Use app's documents directory to save the recorded video
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        let fileName = "video_\(Date().timeIntervalSince1970).mov"
        let outputURL = documentsPath.appendingPathComponent(fileName)
        
        cameraQueue.async {
            movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        }
    }
    
    func stopVideoRecording(completion: @escaping (Result<Bool, any Error>) -> Void) {
        guard let movieOutput = movieFileOutput else {
            completion(getFailureResult(message: "Movie output not available"))
            return
        }
        guard isRecording else {
            completion(getFailureResult(message: "Not currently recording"))
            return
        }
        
        // Store completion for when recording actually stops
        stopRecordingCompletion = completion

        cameraQueue.async {
            movieOutput.stopRecording()
        }
    }

    func closeCamera(completion: @escaping (Result<Bool, any Error>) -> Void) {
        cameraQueue.async {
            // Stop recording if currently recording
            if self.isRecording {
                self.movieFileOutput?.stopRecording()
            }

            self.captureSession?.stopRunning()
            
            DispatchQueue.main.async {
                self.bufferLock.lock()
                self.previewPixelBuffer = nil
                self.bufferLock.unlock()
                
                self.captureSession = nil
                self.videoDeviceInput = nil
                self.audioDeviceInput = nil
                
                self.previewVideoOutput = nil
                if let textureId = self.previewTextureId {
                    self.textureRegistry?.unregisterTexture(textureId)
                }
                self.previewTextureId = nil
                self.textureRegistry = nil
                
                self.imageStreamSink = nil
                self.audioStreamSink = nil
                
                self.movieFileOutput = nil
                
                completion(.success(true))
            }
        }
    }

    /// Gets the supported sizes with the fps list from the video device
    func getSupportedVideoInputSizes() {
        guard let formats = videoDeviceInput?.device.formats else {
            return
        }
        
        let commonSizes: [IOSSize] = [
            IOSSize(width: 1280, height: 720),  // HD
            IOSSize(width: 1920, height: 1080), // Full HD
            IOSSize(width: 2560, height: 1440), // 2K
            IOSSize(width: 3840, height: 2160), // 4K
        ]
        
        for format in formats {
            let dimensions = format.formatDescription.dimensions
            let width = Double(dimensions.width)
            let height = Double(dimensions.height)
            
            // Check if the format matches one of the common sizes
            if let index = commonSizes.firstIndex(where: {
                $0.width == width && $0.height == height
            })
            {
                // Get supported frame rates up to 60 fps
                let frameRates = format.videoSupportedFrameRateRanges.filter({
                    $0.maxFrameRate <= 60
                })
                .map {
                    range -> Int64 in
                    return Int64(range.maxFrameRate)
                }
                
                // Check If the size already added or not
                if let sizeIndex = iosCameraSizes.firstIndex(where: {
                    $0.width == width && $0.height == height
                })
                {
                    // Check the fps already exists in the size or not
                    // Add it if it doesn't
                    for fps in frameRates {
                        if !iosCameraSizes[sizeIndex].frameRates.contains(fps) {
                            iosCameraSizes[sizeIndex].frameRates.append(fps)
                        }
                    }
                }
                else {
                    iosCameraSizes.append(
                        IOSCameraSize(
                            width: width,
                            height: height,
                            frameRates: frameRates
                        )
                    )
                }
            }
        }
    }

    /// Checks if the size and fps is supported by the video device, returns the format if supported
    func getSupportedVideoInputFormat(
        width: Double,
        height: Double,
        frameRate: Int64
    ) -> AVCaptureDevice.Format?
    {
        guard let formats = videoDeviceInput?.device.formats else {
           return nil
        }
        
        // Iterate through available formats
        for format in formats {
            let dimensions = format.formatDescription.dimensions
            let frameRates = format.videoSupportedFrameRateRanges.map {
                range -> Int64 in
                return Int64(range.maxFrameRate)
            }
            
            // return the matched format
            if Double(dimensions.width) == width
                && Double(dimensions.height) == height
                && frameRates.contains(frameRate) {
                return format
            }
        }
        
        return nil
    }

    /// Rotates the video outputs based on the device orientation
    func rotateVideoOutput() {
        let orientation: AVCaptureVideoOrientation
        switch UIDevice.current.orientation {
            case .portrait: orientation = .portrait
            case .landscapeRight: orientation = .landscapeLeft
            case .landscapeLeft: orientation = .landscapeRight
            case .portraitUpsideDown: orientation = .portraitUpsideDown
            default: orientation = .portrait  // Default case
        }
        
        // Rotate the camera preview
        let previewConnection = previewVideoOutput?.connection(with: .video)
        if previewConnection?.isVideoOrientationSupported == true {
            previewConnection?.videoOrientation = orientation
        }
        
        // Rotate the video recorder output if video is not being recorded
        if let connection = movieFileOutput?.connection(with: .video),
            connection.isVideoOrientationSupported,
            !isRecording {
            connection.videoOrientation = orientation
        }
    }
    
    // Gets the failure result dynamically
    func getFailureResult<T>(
        domain: String = "Camera",
        code: Int = -1,
        message: String
    ) -> Result<T, Error> {
        .failure(
            NSError(
                domain: domain,
                code: code,
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        )
    }

    /// FlutterTexture protocol: called by Flutter to get the latest camera frame
    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        bufferLock.lock()  // Wait if captureOutput is currently updating
        defer {
            bufferLock.unlock()
        } // Always unlock when function exits
        
        guard let buffer = previewPixelBuffer else {
            return nil
        }
        return Unmanaged.passRetained(buffer)
    }

    /// AVCaptureVideoDataOutputSampleBufferDelegate: called when a new camera frame is available
    /// AVCaptureAudioDataOutputSampleBufferDelegate: called when a new audio frame is available
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        if output == previewVideoOutput {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                return
            }

            // Lock before accessing shared resource
            bufferLock.lock()
            previewPixelBuffer = pixelBuffer
            bufferLock.unlock()

            // Notify Flutter on the main thread that a new frame is available for the texture
            if let registry = textureRegistry, let textureId = previewTextureId {
                DispatchQueue.main.async {
                    registry.textureFrameAvailable(textureId)
                }
            }
            
            // Increase frame count
            frameCount += 1
            
            // Convert the pixel buffer to jpeg image and send it to flutter
            // if imageStream is available and desired number of frames are skipped
            if let imageStreamSink = imageStreamSink,
                frameCount % frameSkipInterval == 0 {
                DispatchQueue.global(qos: .background).async {
                    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                    let context = CIContext()
                    if let jpegData = context.jpegRepresentation(
                        of: ciImage,
                        colorSpace: CGColorSpaceCreateDeviceRGB(),
                        options: [:]
                    ) {
                        DispatchQueue.main.async {
                            imageStreamSink(FlutterStandardTypedData(bytes: jpegData))
                        }
                    }
                }
            }
        } else if output == audioDataOutput {
            if let audioStreamSink = audioStreamSink {
                // Process audio data in background
                DispatchQueue.global(qos: .userInitiated).async {
                    var audioBuffer = [UInt8]()
                    var blockBuffer: CMBlockBuffer?
                    var audioBufferList = AudioBufferList(
                        mNumberBuffers: 1,
                        mBuffers: AudioBuffer(
                            mNumberChannels: 0,
                            mDataByteSize: 0,
                            mData: nil
                        )
                    )

                    let status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
                        sampleBuffer,
                        bufferListSizeNeededOut: nil,
                        bufferListOut: &audioBufferList,
                        bufferListSize: MemoryLayout<AudioBufferList>.size,
                        blockBufferAllocator: kCFAllocatorDefault,
                        blockBufferMemoryAllocator: kCFAllocatorDefault,
                        flags: 0,
                        blockBufferOut: &blockBuffer
                    )

                    guard status == noErr, let data = audioBufferList.mBuffers.mData else {
                        return
                    }

                    let dataSize = Int(audioBufferList.mBuffers.mDataByteSize)
                    let buffer = data.assumingMemoryBound(to: UInt8.self)
                    audioBuffer.append(contentsOf: UnsafeBufferPointer(start: buffer, count: dataSize))
                    
                    DispatchQueue.main.async {
                        audioStreamSink(FlutterStandardTypedData(bytes: Data(audioBuffer)))
                    }
                }
            }
        }
    }
    
    /// Video recording actually started successfully
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didStartRecordingTo fileURL: URL,
        from connections: [AVCaptureConnection]
    ) {
        isRecording = true
        
        DispatchQueue.main.async {
            self.startRecordingCompletion?(.success(true))
            self.startRecordingCompletion = nil
        }
    }
    
    /// Video recording actually finished
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        isRecording = false
        
        DispatchQueue.main.async {
            if let error = error {
                self.stopRecordingCompletion?(.failure(error))
                // Also handle case where start recording failed
                self.startRecordingCompletion?(.failure(error))
            } else {
                self.stopRecordingCompletion?(.success(true))
            }
            
            self.startRecordingCompletion = nil
            self.stopRecordingCompletion = nil
        }
    }
}

// A stream handler for listening flutter side image stream events
fileprivate class ImageStreamHandler: NSObject, FlutterStreamHandler {
    private weak var owner: AppDelegate?
    
    init(owner: AppDelegate) {
        self.owner = owner
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        owner?.imageStreamSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        owner?.frameCount = 0
        owner?.imageStreamSink = nil
        return nil
    }
}


// A stream handler for listening flutter side audio stream events
fileprivate class AudioStreamHandler: NSObject, FlutterStreamHandler {
    private weak var owner: AppDelegate?
    
    init(owner: AppDelegate) {
        self.owner = owner
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        owner?.audioStreamSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        owner?.audioStreamSink = nil
        return nil
    }
}
