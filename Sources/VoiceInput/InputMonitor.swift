import Cocoa
import CoreGraphics

protocol InputMonitorDelegate: AnyObject {
    func didStartRecording()
    func didStopRecording()
}

class InputMonitor {
    weak var delegate: InputMonitorDelegate?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var isRecording = false
    
    func startMonitoring() {
        let eventMask = (1 << CGEventType.flagsChanged.rawValue)
        
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        
        eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let monitor = Unmanaged<InputMonitor>.fromOpaque(refcon).takeUnretainedValue()
                return monitor.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: pointer
        )
        
        guard let eventTap = eventTap else {
            print("Failed to create event tap. Make sure the app has Accessibility permissions.")
            return
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    func stopMonitoring() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            if let runLoopSource = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            }
        }
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .flagsChanged {
            let flags = event.flags
            let hasFnKey = flags.contains(.maskSecondaryFn)
            
            if hasFnKey && !isRecording {
                isRecording = true
                delegate?.didStartRecording()
                return nil
            } else if !hasFnKey && isRecording {
                isRecording = false
                delegate?.didStopRecording()
                return nil
            }
            
            let keycode = event.getIntegerValueField(.keyboardEventKeycode)
            if keycode == 63 {
                return nil
            }
        }
        return Unmanaged.passRetained(event)
    }
}
