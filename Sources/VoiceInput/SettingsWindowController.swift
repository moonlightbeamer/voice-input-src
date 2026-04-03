import Cocoa
import SwiftUI

class SettingsWindowController: NSWindowController {
    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "LLM Settings"
        super.init(window: window)
        
        let hostingView = NSHostingView(rootView: SettingsView())
        window.contentView = hostingView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct SettingsView: View {
    @AppStorage("LLMBaseURL") var baseURL: String = "https://api.openai.com/v1"
    @AppStorage("LLMAPIKey") var apiKey: String = ""
    @AppStorage("LLMModel") var model: String = "gpt-4o-mini"
    
    @State private var testResult: String = ""
    @State private var isTesting = false
    
    var body: some View {
        Form {
            Section(header: Text("OpenAI Compatible API")) {
                TextField("Base URL", text: $baseURL)
                SecureField("API Key (leave blank to clear)", text: $apiKey)
                TextField("Model", text: $model)
            }
            
            HStack {
                Button("Test Connection") {
                    testConnection()
                }
                .disabled(isTesting || apiKey.isEmpty)
                
                Spacer()
                
                Button("Save & Close") {
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top)
            
            if !testResult.isEmpty {
                Text(testResult)
                    .foregroundColor(testResult.contains("Success") ? .green : .red)
                    .font(.caption)
                    .padding(.top, 4)
            }
        }
        .padding(20)
        .frame(width: 400, height: 260)
    }
    
    func testConnection() {
        isTesting = true
        testResult = "Testing..."
        
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            testResult = "Invalid Base URL"
            isTesting = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "messages": [["role": "user", "content": "Hello! Reply with 'Hi'"]],
            "max_tokens": 5
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isTesting = false
                if let error = error {
                    testResult = "Error: \(error.localizedDescription)"
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if (200...299).contains(httpResponse.statusCode) {
                        testResult = "Success!"
                    } else {
                        testResult = "Failed: HTTP \(httpResponse.statusCode)"
                    }
                }
            }
        }.resume()
    }
}
