import Cocoa

let logPath = "/tmp/voiceinput_launch.log"
try? "Starting VoiceInput...\n".write(toFile: logPath, atomically: true, encoding: .utf8)

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

