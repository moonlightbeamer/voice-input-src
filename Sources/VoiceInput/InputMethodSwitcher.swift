import Cocoa
import Carbon

class InputMethodSwitcher {
    static let shared = InputMethodSwitcher()
    
    static func injectText(_ text: String) {
        guard !text.isEmpty else { return }
        
        let clipboard = NSPasteboard.general
        
        // Save old contents robustly
        var oldItems: [NSPasteboardItem] = []
        if let items = clipboard.pasteboardItems {
            for item in items {
                let copy = NSPasteboardItem()
                for type in item.types {
                    if let data = item.data(forType: type) {
                        copy.setData(data, forType: type)
                    }
                }
                oldItems.append(copy)
            }
        }

        let currentInputSource = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        var changedInputSource = false
        
        let filter = [kTISPropertyInputSourceType as String: kTISTypeKeyboardLayout as String] as CFDictionary
        if let sources = TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource] {
            for source in sources {
                if let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID),
                   let id = Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String? {
                    if id == "com.apple.keylayout.ABC" || id == "com.apple.keylayout.US" {
                        TISSelectInputSource(source)
                        changedInputSource = true
                        break
                    }
                }
            }
        }
        
        clipboard.clearContents()
        clipboard.setString(text, forType: .string)
        
        // Delay to allow OS to register the new input source and clipboard change
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let vKeyCode: CGKeyCode = 9 // 'v'
            let cmdVDown = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: true)
            let cmdVUp = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: false)
            
            cmdVDown?.flags = .maskCommand
            cmdVUp?.flags = .maskCommand
            
            cmdVDown?.post(tap: .cgSessionEventTap)
            cmdVUp?.post(tap: .cgSessionEventTap)
            
            // Delay to wait for the target application to process the paste operation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if changedInputSource {
                    TISSelectInputSource(currentInputSource)
                }
                
                clipboard.clearContents()
                if !oldItems.isEmpty {
                    clipboard.writeObjects(oldItems)
                }
            }
        }
    }
}
