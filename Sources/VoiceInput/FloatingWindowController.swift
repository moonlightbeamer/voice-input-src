import Cocoa
import SwiftUI

class FloatingWindowController: NSWindowController {
    var capsuleView: CapsuleView
    var hostingView: NSHostingView<CapsuleView>?
    var windowModel = WindowModel()
    
    private var speechRecognizer = SpeechRecognizer()
    private var audioEngine = AudioEngine()
    
    init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 100),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        
        capsuleView = CapsuleView(model: windowModel, audioEngine: audioEngine)
        let hosting = NSHostingView(rootView: capsuleView)
        hosting.wantsLayer = true
        hosting.layer?.backgroundColor = NSColor.clear.cgColor
        
        panel.contentView = hosting
        
        super.init(window: panel)
        self.hostingView = hosting
        
        setupCallbacks()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCallbacks() {
        speechRecognizer.onTranscriptionUpdate = { [weak self] text, isFinal in
            DispatchQueue.main.async {
                self?.windowModel.text = text
            }
        }
        
        audioEngine.onBufferReceived = { [weak self] buffer in
            self?.speechRecognizer.append(buffer)
        }
    }
    
    func show() {
        guard let window = self.window else { return }
        
        if let screen = NSScreen.main {
            let x = screen.frame.midX - 300
            let y = screen.frame.minY + 80
            
            window.setFrame(NSRect(x: x, y: y, width: 600, height: 100), display: true)
        }
        
        window.makeKeyAndOrderFront(nil)
        windowModel.isAnimatingIn = true
    }
    
    func hide() {
        windowModel.isAnimatingIn = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.window?.orderOut(nil)
            self.windowModel.text = ""
            self.windowModel.isRefining = false
        }
    }
    
    func startRecording() {
        windowModel.text = ""
        windowModel.isRefining = false
        speechRecognizer.start()
        try? audioEngine.start()
    }
    
    func stopRecordingAndInject() {
        audioEngine.stop()
        speechRecognizer.stop()
        
        let finalText = windowModel.text
        if finalText.isEmpty {
            hide()
            return
        }
        
        if UserDefaults.standard.bool(forKey: "LLMEnabled") {
            windowModel.isRefining = true
            LLMRefiner.shared.refine(text: finalText) { [weak self] refinedText in
                DispatchQueue.main.async {
                    self?.windowModel.isRefining = false
                    self?.hide()
                    InputMethodSwitcher.injectText(refinedText)
                }
            }
        } else {
            hide()
            InputMethodSwitcher.injectText(finalText)
        }
    }
}
