import Foundation

class LLMRefiner {
    static let shared = LLMRefiner()
    
    func refine(text: String, completion: @escaping (String) -> Void) {
        guard !text.isEmpty else {
            completion(text)
            return
        }
        
        let isEnabled = UserDefaults.standard.bool(forKey: "LLMEnabled")
        guard isEnabled else {
            completion(text)
            return
        }
        
        let baseURL = UserDefaults.standard.string(forKey: "LLMBaseURL") ?? "https://api.openai.com/v1"
        let apiKey = UserDefaults.standard.string(forKey: "LLMAPIKey") ?? ""
        let model = UserDefaults.standard.string(forKey: "LLMModel") ?? "gpt-4o-mini"
        
        guard !apiKey.isEmpty, let url = URL(string: "\(baseURL)/chat/completions") else {
            completion(text)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let systemPrompt = """
        You are a cautious and conservative speech recognition corrector. 
        Your ONLY job is to fix obvious speech recognition errors, such as:
        - Chinese homophone errors.
        - English technical terms mistakenly transcribed into phonetically similar Chinese (e.g., '配森' -> 'Python', '杰森' -> 'JSON').
        
        CRUCIAL RULES:
        1. NEVER rewrite, paraphrase, polish, or change the tone of the input.
        2. NEVER remove or add content that changes the meaning.
        3. If the input looks largely correct, return the EXACT original text.
        4. ONLY output the final plain text. Do not include quotes, explanations, or any other formatting around it.
        """
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "temperature": 0.1
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(text)
                return
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
                var cleaned = trimmed
                if cleaned.hasPrefix("\"") && cleaned.hasSuffix("\"") && cleaned.count > 1 {
                    cleaned.removeFirst()
                    cleaned.removeLast()
                }
                completion(cleaned)
            } else {
                completion(text)
            }
        }.resume()
    }
}
