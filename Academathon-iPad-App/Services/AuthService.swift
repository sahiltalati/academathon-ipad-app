import Foundation

enum AuthError: LocalizedError {
    case invalidCredentials
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Invalid email or password."
        case .serverError(let message): return message
        }
    }
}

private struct ErrorResponse: Codable {
    let error: String
}

struct AuthService {
    private let baseURL = "https://api.academathon.com"

    func login(email: String, password: String) async throws -> LoginResponse {
        guard let url = URL(string: "\(baseURL)/auth/login") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["email": email, "password": password])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let message = (try? JSONDecoder().decode(ErrorResponse.self, from: data))?.error
            throw message.map { AuthError.serverError($0) } ?? AuthError.invalidCredentials
        }

        return try JSONDecoder().decode(LoginResponse.self, from: data)
    }
}
