import Foundation

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isLoggedIn = false

    private let authService = AuthService()

    func login() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await authService.login(email: email, password: password)
            KeychainService.save(token: response.token)
            isLoggedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
