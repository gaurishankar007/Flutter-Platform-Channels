import AVFoundation

class VideoRecordHandler: NSObject, AVCaptureFileOutputRecordingDelegate {
    // The output for video recording
    private var _movieFileOutput: AVCaptureMovieFileOutput?
    // Video recording state
    private var startRecordingCompletion: ((Result<Bool, Error>) -> Void)?
    private var stopRecordingCompletion: ((Result<Bool, Error>) -> Void)?
    
    var movieFileOutput: AVCaptureMovieFileOutput? {
        get { _movieFileOutput }
    }
    
    var isRecording: Bool {
       get {
            _movieFileOutput?.isRecording ?? false
        }
    }
    
    /// Add movie file output to the AVCaptureSession for video recording.
    func addOutput(session: AVCaptureSession) {
        let movieOutput = AVCaptureMovieFileOutput()
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
            self._movieFileOutput = movieOutput
        }
    }
    
    func startVideoRecording(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let movieOutput = _movieFileOutput else {
            completion(CameraUtil.failureResult("Movie output not available"))
            return
        }
        guard !movieOutput.isRecording else {
            completion(CameraUtil.failureResult("Video recording already started"))
            return
        }
        
        rotateVideoOrientation()
        
        // Store completion for when recording actually starts
        startRecordingCompletion = completion
        
        // Use app's documents directory to save the recorded video
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        let fileName = "video_\(Date().timeIntervalSince1970).mov"
        let outputURL = documentsPath.appendingPathComponent(fileName)
        
        DispatchQueue.global(qos: .userInitiated).async {
            movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        }
    }
    
    func stopVideoRecording(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let movieOutput = _movieFileOutput else {
            completion(CameraUtil.failureResult("Movie output not available"))
            return
        }
        guard movieOutput.isRecording else {
            completion(CameraUtil.failureResult("Not currently recording"))
            return
        }
        
        // Store completion for when recording actually stops
        stopRecordingCompletion = completion

        DispatchQueue.global(qos: .userInitiated).async {
            movieOutput.stopRecording()
        }
    }
    
    private func rotateVideoOrientation() {
        let orientation: AVCaptureVideoOrientation
        
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = .portrait
        case .landscapeRight:
            orientation = .landscapeLeft
        case .landscapeLeft:
            orientation = .landscapeRight
        case .portraitUpsideDown:
            orientation = .portraitUpsideDown
        default:
            orientation = .portrait
        }
        
        // Rotate the video recorder output if video is not being recorded
        if let connection = movieFileOutput?.connection(with: .video),
            connection.isVideoOrientationSupported {
            connection.videoOrientation = orientation
        }
    }
    
    /// Stops the recording if recording is in progresss and removes movie file output.
    func dispose() {
        if _movieFileOutput?.isRecording == true {
            stopVideoRecording() { result in }
        }
        _movieFileOutput = nil
    }
    
    /// Video recording actually started successfully
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didStartRecordingTo fileURL: URL,
        from connections: [AVCaptureConnection]
    ) {
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
