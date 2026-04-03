import Speech
import AVFoundation

class SpeechRecognizer {
    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    var onTranscriptionUpdate: ((String, Bool) -> Void)?
    
    func start() {
        let languageCode = UserDefaults.standard.string(forKey: "SelectedLanguage") ?? "en-US"
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: languageCode))
        
        guard let recognizer = recognizer, recognizer.isAvailable else {
            print("Speech recognizer not available for \(languageCode)")
            return
        }
        
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { return }
        
        request.shouldReportPartialResults = true
        if #available(macOS 14, *) {
            request.requiresOnDeviceRecognition = false
        }
        
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            if let result = result {
                self?.onTranscriptionUpdate?(result.bestTranscription.formattedString, result.isFinal)
            }
            if error != nil {
                self?.stop()
            }
        }
    }
    
    func append(_ buffer: AVAudioPCMBuffer) {
        request?.append(buffer)
    }
    
    func stop() {
        request?.endAudio()
        request = nil
        recognitionTask = nil
    }
    
    func cancel() {
        recognitionTask?.cancel()
        request = nil
        recognitionTask = nil
    }
}
