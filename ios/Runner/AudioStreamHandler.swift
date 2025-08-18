import AVFoundation
import Flutter

class AudioStreamHandler: NSObject, FlutterStreamHandler, AVCaptureAudioDataOutputSampleBufferDelegate {
    /// Event sink for the audio stream
    var audioStreamSink: FlutterEventSink?
    
    /// Add audio data output to the AVCaptureSession for receiving audio frames.
    func addOutput(session: AVCaptureSession) {
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "audioQueue"))
        if session.canAddOutput(audioOutput) {
            session.addOutput(audioOutput)
        }
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        audioStreamSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        audioStreamSink = nil
        return nil
    }
    
    /// This method is called when a new audio frame is available (AVCaptureAudioDataOutputSampleBufferDelegate).
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let audioStreamSink = audioStreamSink else {
            return
        }
        
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
                audioStreamSink(
                    FlutterStandardTypedData(bytes: Data(audioBuffer))
                )
            }
        }
    }
}
