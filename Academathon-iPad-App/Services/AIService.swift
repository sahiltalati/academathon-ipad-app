import Foundation
import UIKit

// MARK: - AI Service

struct AIService {

    // Key is stored in Config.swift which is gitignored — never committed.
    // For a shipped app you'd route this through your own backend instead.
    private let apiKey = Config.openAIKey
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let model = "gpt-4o"

    /// Sends a snapshot of the whiteboard canvas to GPT-4o-mini and returns
    /// a plain-English explanation of the concepts shown.
    func explain(image: UIImage) async throws -> String {
        // 1. Convert the UIImage to PNG bytes, then to a base64 string.
        //    Base64 is how binary data (like an image) is safely embedded in JSON.
        guard let pngData = image.pngData() else {
            throw AIError.imageCaptureFailed
        }
        let base64String = pngData.base64EncodedString()

        // 2. Build the request body using our Codable structs (defined below).
        let requestBody = ChatRequest(
            model: model,
            maxTokens: 400,
            messages: [
                ChatMessage(role: "user", content: [
                    .image(base64PNG: base64String),
                    .text("""
                    This is a photo of a tutoring whiteboard. \
                    Look carefully at exactly what is written or drawn — \
                    read every number, equation, word, or diagram you can see. \
                    First state specifically what you see (e.g. "I can see 5 + 3 = 8"). \
                    Then explain what those specific things mean in simple, \
                    friendly language a student would understand. \
                    Be concrete and specific to the actual content in the image — \
                    do not give generic advice about studying.
                    """)
                ])
            ]
        )

        // 3. Build the URLRequest — method, headers, body.
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        // 4. Fire the request with async/await. URLSession suspends here
        //    without blocking the main thread until the response arrives.
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw AIError.networkError("Unexpected response type.")
        }
        guard http.statusCode == 200 else {
            throw AIError.networkError("OpenAI returned status \(http.statusCode).")
        }

        // 5. Decode the JSON response using our Codable structs.
        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = chatResponse.choices.first?.message.content else {
            throw AIError.networkError("AI returned an empty response.")
        }
        return content
    }
}

// MARK: - Request Models

private struct ChatRequest: Encodable {
    let model: String
    let maxTokens: Int
    let messages: [ChatMessage]

    enum CodingKeys: String, CodingKey {
        case model
        case maxTokens = "max_tokens"   // snake_case in JSON, camelCase in Swift
        case messages
    }
}

private struct ChatMessage: Encodable {
    let role: String
    let content: [ContentItem]
}

/// A single item inside a message's content array.
/// OpenAI messages can contain a mix of text and images, so each item
/// has a `type` field and then either a `text` or `image_url` payload.
private struct ContentItem: Encodable {
    let type: String
    let text: String?
    let imageUrl: ImageURLWrapper?

    struct ImageURLWrapper: Encodable {
        let url: String
    }

    enum CodingKeys: String, CodingKey {
        case type, text
        case imageUrl = "image_url"
    }

    // Custom encoder so nil fields are omitted entirely from the JSON
    // (OpenAI is strict — extra null fields can cause errors).
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
    }

    /// Factory for a plain text content item.
    static func text(_ value: String) -> ContentItem {
        ContentItem(type: "text", text: value, imageUrl: nil)
    }

    /// Factory for an image content item (base64-encoded PNG).
    static func image(base64PNG: String) -> ContentItem {
        let dataURL = "data:image/png;base64,\(base64PNG)"
        return ContentItem(type: "image_url", text: nil, imageUrl: ImageURLWrapper(url: dataURL))
    }
}

// MARK: - Response Models

private struct ChatResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }

    struct Message: Decodable {
        let content: String
    }
}

// MARK: - Errors

enum AIError: LocalizedError {
    case imageCaptureFailed
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .imageCaptureFailed:
            return "Could not capture the canvas image."
        case .networkError(let message):
            return "AI request failed: \(message)"
        }
    }
}
