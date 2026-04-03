import Cocoa
import AVFoundation
import Speech

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var settingsController: SettingsWindowController?
    var floatingController: FloatingWindowController?
    var inputMonitor: InputMonitor?
    
    let defaultLanguageKey = "SelectedLanguage"
    let languageOptions = [
        ("en-US", "English"),
        ("zh-CN", "Simplified Chinese"),
        ("zh-TW", "Traditional Chinese"),
        ("ja-JP", "Japanese"),
        ("ko-KR", "Korean")
    ]
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let data = "applicationDidFinishLaunching called\n".data(using: .utf8), let handle = FileHandle(forWritingAtPath: "/tmp/voiceinput_launch.log") { handle.seekToEndOfFile(); handle.write(data); handle.closeFile() }
        
        // Request permissions
        SFSpeechRecognizer.requestAuthorization { authStatus in }
        
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        setupMenu()
        
        // Initialize Core Components
        floatingController = FloatingWindowController()
        inputMonitor = InputMonitor()
        inputMonitor?.delegate = self
        inputMonitor?.startMonitoring()
    }
    
    func setupMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "Voice Input")
            button.title = "🎙️"
        }
        
        let menu = NSMenu()
        
        // Language Menu
        let langMenu = NSMenu()
        let currentLang = UserDefaults.standard.string(forKey: defaultLanguageKey) ?? "zh-CN"
        
        for (code, name) in languageOptions {
            let item = NSMenuItem(title: name, action: #selector(selectLanguage(_:)), keyEquivalent: "")
            item.representedObject = code
            if code == currentLang {
                item.state = .on
            }
            langMenu.addItem(item)
        }
        
        let langItem = NSMenuItem(title: "Language", action: nil, keyEquivalent: "")
        langItem.submenu = langMenu
        menu.addItem(langItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // LLM Settings
        let llmMenu = NSMenu()
        let enableLLMItem = NSMenuItem(title: "Enable LLM Refinement", action: #selector(toggleLLM(_:)), keyEquivalent: "")
        enableLLMItem.state = UserDefaults.standard.bool(forKey: "LLMEnabled") ? .on : .off
        llmMenu.addItem(enableLLMItem)
        
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings(_:)), keyEquivalent: "")
        llmMenu.addItem(settingsItem)
        
        let llmMainItem = NSMenuItem(title: "LLM Refinement", action: nil, keyEquivalent: "")
        llmMainItem.submenu = llmMenu
        menu.addItem(llmMainItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc func selectLanguage(_ sender: NSMenuItem) {
        guard let code = sender.representedObject as? String else { return }
        UserDefaults.standard.set(code, forKey: defaultLanguageKey)
        setupMenu() // Refresh checkmarks
    }
    
    @objc func toggleLLM(_ sender: NSMenuItem) {
        let isEnabled = !UserDefaults.standard.bool(forKey: "LLMEnabled")
        UserDefaults.standard.set(isEnabled, forKey: "LLMEnabled")
        sender.state = isEnabled ? .on : .off
    }
    
    @objc func openSettings(_ sender: Any?) {
        if settingsController == nil {
            settingsController = SettingsWindowController()
        }
        settingsController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

extension AppDelegate: InputMonitorDelegate {
    func didStartRecording() {
        DispatchQueue.main.async {
            self.floatingController?.show()
            self.floatingController?.startRecording()
        }
    }
    
    func didStopRecording() {
        DispatchQueue.main.async {
            self.floatingController?.stopRecordingAndInject()
        }
    }
}
