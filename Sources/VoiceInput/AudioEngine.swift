import AVFoundation

class AudioEngine: ObservableObject {
    private var engine = AVAudioEngine()
    private var inputFormat: AVAudioFormat?
    
    @Published var rmsValue: Float = 0.0
    
    var onBufferReceived: ((AVAudioPCMBuffer) -> Void)?
    
    func start() throws {
        let inputNode = engine.inputNode
        inputFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, time in
            guard let self = self else { return }
            self.onBufferReceived?(buffer)
            self.calculateRMS(buffer: buffer)
        }
        
        engine.prepare()
        try engine.start()
    }
    
    func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        DispatchQueue.main.async {
            self.rmsValue = 0.0
        }
    }
    
    private func calculateRMS(buffer: AVAudioPCMBuffer) {
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        
        guard let channelData = buffer.floatChannelData else { return }
        
        var sum: Float = 0
        for channel in 0..<channelCount {
            let data = channelData[channel]
            for frame in 0..<frameLength {
                let sample = data[frame]
                sum += sample * sample
            }
        }
        
        let rms = sqrt(sum / Float(channelCount * frameLength))
        
        DispatchQueue.main.async {
            let targetRMS = min(rms * 10.0, 1.0)
            
            if targetRMS > self.rmsValue {
                self.rmsValue = self.rmsValue + (targetRMS - self.rmsValue) * 0.40
            } else {
                self.rmsValue = self.rmsValue + (targetRMS - self.rmsValue) * 0.15
            }
        }
    }
}
