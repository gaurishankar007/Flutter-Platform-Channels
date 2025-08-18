import AVFoundation
import Flutter
import UIKit

@main
@objc
class AppDelegate: FlutterAppDelegate, IOSCameraHostApi {
    private let cameraUtil = CameraUtil()
    private let cameraPreviewHandler = CameraPreviewHandler()
    private let audioStreamHandler = AudioStreamHandler()
    private let videoRecordHandler = VideoRecordHandler()
    
    // Add a dedicated queue for camera operations
    private let cameraQueue = DispatchQueue(label: "CameraQueue", qos: .userInitiated)
    // The camera session that manages input and output
    private var captureSession: AVCaptureSession?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?)
    -> Bool {
        // Get the Flutter view controller
        let controller = window?.rootViewController as! FlutterViewController
        
        // Set up the Pigeon API for camera calls from Dart
        IOSCameraHostApiSetup.setUp(binaryMessenger: controller.binaryMessenger, api: self)
        
        // Set up the event channel for image streaming
        let imageStreamChannel = FlutterEventChannel(
            name: "app.vaiolin.ai/image_stream",
            binaryMessenger: controller.binaryMessenger
        )
        imageStreamChannel.setStreamHandler(cameraPreviewHandler)
        
        // Set up the event channel for audio streaming
        let audioStreamChannel = FlutterEventChannel(
            name: "app.vaiolin.ai/audio_stream",
            binaryMessenger: controller.binaryMessenger
        )
        audioStreamChannel.setStreamHandler(audioStreamHandler)
        
        // Register other Flutter plugins
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func requestCameraAccess(completion: @escaping (Result<Bool, any Error>) -> Void) {
       do {
           cameraUtil.requestCameraAccess { granted in
               completion(.success(granted))
           }
       } catch {
           completion(CameraUtil.failureResult(error.localizedDescription))
       }
    }
    
    func requestMicrophoneAccess(completion: @escaping (Result<Bool, any Error>) -> Void) {
        do {
            cameraUtil.requestMicrophoneAccess { granted in
                completion(.success(granted))
            }
        } catch {
            completion(CameraUtil.failureResult(error.localizedDescription))
        }
    }

    func openCamera(
        request: IOSCameraRequest,
        completion: @escaping (Result<IOSCameraData, any Error>) -> Void)
    {
        do {
            // Check camera permissions are granted or not
            if let cameraPermissionError = cameraUtil.checkCameraPermissions() {
                completion(CameraUtil.failureResult(cameraPermissionError))
                return
            }

            // Create and configure the camera session
            let session = AVCaptureSession()
            session.beginConfiguration()
            session.sessionPreset = .high

            // Add the video input device (Camera) to the AVCaptureSession
            let position: AVCaptureDevice.Position = (request.cameraIndex == 0) ? .back : .front
            guard
                let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position),
                let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                session.canAddInput(videoInput)
            else {
                completion(CameraUtil.failureResult("No camera device found"))
                return
            }
            session.addInput(videoInput)

            // Updates video device format and gets supported vidoe sizes
            try cameraUtil.updateVideoDeviceFormat(
               videoDevice,
               videoInputSize: request.videoInputSize,
               videoFrameRate: request.videoInputFrameRate,
            )

            // Add audio device input to the AVCaptureSession
            guard
                let audioDevice = AVCaptureDevice.default(.builtInMicrophone, for: .audio, position: .unspecified),
                let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
                session.canAddInput(audioInput)
            else {
                completion(CameraUtil.failureResult("No audio device found"))
                return
            }
            session.addInput(audioInput)

            // Add video output
            cameraPreviewHandler.addOutput(session: session)
            // Add audio output
            audioStreamHandler.addOutput(session: session)
            // Add movie file output
            videoRecordHandler.addOutput(session: session)

            session.commitConfiguration()
            self.captureSession = session

            // Register a flutter texture
            try cameraPreviewHandler.registerTexture(
                window: self.window,
                imageStreamFrameSkipInterval: request.imageStreamFrameSkipInterval
            )
            
            let iosCameraData = IOSCameraData(
                textureId: cameraPreviewHandler.flutterTextureID,
                videoInputSize: cameraUtil.getActiveVideoSize(),
                videoInputFrameRate: cameraUtil.getActiveVideoFrameRate(),
                supportedSizes: cameraUtil.videoSizes,
                rotationDegrees: cameraUtil.getVideoOutputRotationDegrees(),
            )
            
            // Start the session in background thread
            cameraQueue.async {
                session.startRunning()
                
                DispatchQueue.main.async {
                    completion(.success(iosCameraData))
                }
            }
        } catch {
           completion(CameraUtil.failureResult(error.localizedDescription))
       }
    }

    func updateCameraVideoOutputOrientation(completion: @escaping (Result<Int64, any Error>) -> Void) {
        do {
            let rotationDegrees = cameraUtil.getVideoOutputRotationDegrees()
            completion(.success(rotationDegrees))
        } catch {
            completion(CameraUtil.failureResult(error.localizedDescription))
        }
    }
        
    func startVideoRecording(completion: @escaping (Result<Bool, any Error>) -> Void) {
        do {
            videoRecordHandler.startVideoRecording(completion: completion)
        } catch {
            completion(CameraUtil.failureResult(error.localizedDescription))
        }
    }
    
    func stopVideoRecording(completion: @escaping (Result<Bool, any Error>) -> Void) {
        do {
            videoRecordHandler.stopVideoRecording(completion: completion)
        } catch {
            completion(CameraUtil.failureResult(error.localizedDescription))
        }
    }

    func closeCamera(completion: @escaping (Result<Bool, any Error>) -> Void) {
        cameraQueue.async {
            self.cameraUtil.dispose()
            self.videoRecordHandler.dispose()
            self.captureSession?.stopRunning()
            self.captureSession = nil
            
            DispatchQueue.main.async {
                self.cameraPreviewHandler.dispose()
                completion(.success(true))
            }
        }
    }
}
