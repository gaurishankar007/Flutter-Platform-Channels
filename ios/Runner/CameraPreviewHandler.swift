import AVFoundation
import Flutter

class CameraPreviewHandler: NSObject, FlutterStreamHandler, FlutterTexture, AVCaptureVideoDataOutputSampleBufferDelegate {
    // Event sink for the image stream
    var imageStreamSink: FlutterEventSink?
    // The latest camera frame as a pixel buffer
    private var previewPixelBuffer: CVPixelBuffer?
    // Thread-safe lock to prevent race conditions when accessing previewPixelBuffer
    // from both the camera capture thread (captureOutput) and Flutter UI thread
    private let bufferLock = NSLock()
    // The output for preview video frames
    private var _previewVideoOutput: AVCaptureVideoDataOutput?
    // Flutter texture registry for displaying camera preview
    private var textureRegistry: FlutterTextureRegistry?
    // The texture ID used by Flutter to render the camera preview
    private var previewTextureId: Int64 = 0
    // The interval between sending image frames while streaming image
    private var frameSkipInterval: Int64 = 1
    // Total number of camera frames processed
    var frameCount: Int64 = 0
    
    var previewVideoOutput: AVCaptureVideoDataOutput? {
        get { _previewVideoOutput }
    }
    
    var flutterTextureID: Int64 {
        get { previewTextureId ?? 0 }
    }
    
    /// Add video output to receive camera frames for previewing the camera.
    func addOutput(session: AVCaptureSession) {
        let previewVideoOutput = AVCaptureVideoDataOutput()
        previewVideoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if session.canAddOutput(previewVideoOutput) {
            session.addOutput(previewVideoOutput)
            self._previewVideoOutput = previewVideoOutput
        }
    }
    
    /// Registers a flutter texture for previewing camera frames.
    func registerTexture(
        window: UIWindow?,
        imageStreamFrameSkipInterval: Int64,
    ) throws {
        // Get the flutter texture registry
        textureRegistry = window?.rootViewController as? FlutterTextureRegistry
        guard let registry = textureRegistry else {
            throw CameraUtil.getError("Texture registry not available")
        }
        // Register the flutter texture
        let textureId = registry.register(self)
        previewTextureId = Int64(textureId)
        
        frameSkipInterval = imageStreamFrameSkipInterval
    }
    
    /// Releases camera preview resourses.
    func dispose() {
        bufferLock.lock()
        previewPixelBuffer = nil
        bufferLock.unlock()
        
        _previewVideoOutput = nil
        textureRegistry?.unregisterTexture(previewTextureId)
        textureRegistry = nil
        previewTextureId = 0
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        imageStreamSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        frameCount = 0
        imageStreamSink = nil
        return nil
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
    
    /// This method is called when a new camera frame is available (AVCaptureVideoDataOutputSampleBufferDelegate).
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        // Lock before accessing shared resource
        bufferLock.lock()
        previewPixelBuffer = pixelBuffer
        bufferLock.unlock()

        // Notify Flutter on the main thread that a new frame is available for the texture
        DispatchQueue.main.async {
            self.textureRegistry?.textureFrameAvailable(self.previewTextureId)
        }
        
        // Don't send image if streaming is not started
        guard let imageStreamSink = self.imageStreamSink else {
            return
        }
        
        // Increase frame count
        frameCount += 1
        
        // Convert the pixel buffer to jpeg image and send it to flutter
        // if imageStream is available and desired number of frames are skipped
        if frameCount % frameSkipInterval == 0 {
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
    }
}

