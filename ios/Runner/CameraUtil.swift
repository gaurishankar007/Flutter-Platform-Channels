import AVFoundation

class CameraUtil {
    private let commonSizes: [IOSSize] = [
        IOSSize(width: 1280, height: 720),  // HD
        IOSSize(width: 1920, height: 1080), // Full HD
        IOSSize(width: 2560, height: 1440), // 2K
        IOSSize(width: 3840, height: 2160), // 4K
    ]
    private var videoDevice: AVCaptureDevice?
    
    // The video device supported sizes
    private var _videoSizes: [IOSCameraSize] = []
    var videoSizes: [IOSCameraSize] {
        get { _videoSizes }
    }
    
    func requestCameraAccess(callback: @escaping (Bool) -> Void) {
        let permissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
                
        switch permissionStatus {
        case .authorized:
            callback(true)
        case .denied, .restricted:
           callback(false)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    callback(granted)
                }
            }
        @unknown default:
            callback(false)
        }
    }
    
    func requestMicrophoneAccess(callback: @escaping (Bool) -> Void) {
        let permissionStatus = AVCaptureDevice.authorizationStatus(for: .audio)
                
        switch permissionStatus {
        case .authorized:
            callback(true)
        case .denied, .restricted:
            callback(false)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    callback(granted)
                }
            }
        @unknown default:
            callback(false)
        }
    }
    
    /// Checks whether camera and microphone permissions are granted or not and if not granted, returns the equivalent error.
    func checkCameraPermissions() -> String?  {
        // Check camera permission
        if AVCaptureDevice.authorizationStatus(for: .video) != .authorized {
            return "Camera permission not granted"
        }
        
        // Check microphone permission for video recording
        if AVCaptureDevice.authorizationStatus(for: .audio) != .authorized {
            return "Microphone permission not granted"
        }
        
        return nil
    }
    
    /// Gets the supported sizes along with the frame rates and updates the video device format based on the provided size and frame rate.
    func updateVideoDeviceFormat(
        _ videoDevice: AVCaptureDevice,
        videoInputSize: IOSSize,
        videoFrameRate: Int64
    ) throws {
        self.videoDevice = videoDevice
        var videoFormat: AVCaptureDevice.Format?
        
        for format in videoDevice.formats {
            let dimensions = format.formatDescription.dimensions
            let width = Double(dimensions.width)
            let height = Double(dimensions.height)
            
            // Only include common sizes and consider video formats (skip photo-only formats)
            guard
                commonSizes.contains(where: { $0.width == width && $0.height == height }),
                format.formatDescription.mediaType == .video
            else {
                continue
            }
            
            // Get supported frame rates up to 60 fps
            let frameRates = format.videoSupportedFrameRateRanges.compactMap { range -> Int64? in
                Int64(range.maxFrameRate) <= 60
                ? Int64(range.maxFrameRate)
                : nil
            }
            
            // Check If the '_cameraSizes' already have the size or not
            if let sizeIndex = _videoSizes.firstIndex(where: {$0.width == width && $0.height == height}) {
                // Check the fps already exists in the size or not
                for fps in frameRates {
                    if !_videoSizes[sizeIndex].frameRates.contains(fps) {
                        _videoSizes[sizeIndex].frameRates.append(fps)
                    }
                }
            }
            else {
                _videoSizes.append(
                    IOSCameraSize(
                        width: width,
                        height: height,
                        frameRates: frameRates
                    )
                )
            }
            
            // Update the video device input format if available
            if videoFormat == nil
                && width == videoInputSize.width
                && height == videoInputSize.height
                && frameRates.contains(videoFrameRate) {
                videoFormat = format
            }
        }
        
        guard let format = videoFormat else {
            throw CameraUtil.getError("Failed to find a compatible video format based on the given input size and frame rate")
        }
        
        // Update video input format and frame rate
        do {
            try videoDevice.lockForConfiguration()
            videoDevice.activeFormat = format
            videoDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale: Int32(videoFrameRate))
            videoDevice.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: Int32(videoFrameRate))
            videoDevice.unlockForConfiguration()
        } catch {
            throw CameraUtil.getError("Failed to lock camera configuration")
        }
    }
    
    /// Returns video output rotation degrees based on the device orientation.
    func getVideoOutputRotationDegrees() -> Int64 {
        switch UIDevice.current.orientation {
        case .portrait:
            return 90
        case .landscapeRight:
            return videoDevice?.position == .back ? 180 : 0
        case .landscapeLeft:
            return videoDevice?.position == .back ? 0 : 180
        case .portraitUpsideDown:
            return 270
        default:
            return 0
        }
    }
    
    /// Returns the camera device active format's size.
    func getActiveVideoSize() -> IOSSize {
        IOSSize(
            width: Double(videoDevice?.activeFormat.formatDescription.dimensions.width ?? 0),
            height: Double(videoDevice?.activeFormat.formatDescription.dimensions.height ?? 0)
        )
    }
    
    /// Returns the camera device active format's frame rate.
    func getActiveVideoFrameRate() -> Int64 {
        Int64(videoDevice?.activeFormat.videoSupportedFrameRateRanges.first?.maxFrameRate ?? 0)
    }
    
    /// Gets the failure result dynamically.
    static func failureResult<T>(
        _ message: String,
        domain: String = "CAMERA",
        code: Int = -1,
    ) -> Result<T, Error> {
        .failure(
            getError(
                message,
                domain: domain,
                code: code,
            )
        )
    }
    
    static func getError(
        _ message: String,
        domain: String = "CAMERA",
        code: Int = -1,
    ) -> NSError {
        NSError(
            domain: domain,
            code: code,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
    
    func dispose() {
        _videoSizes.removeAll()
    }
}
