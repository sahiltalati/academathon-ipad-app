import Foundation

struct LoginResponse: Codable {
    let token: String
    let expiresIn: Int
    let role: String
    let userId: Int
    let username: String
}
