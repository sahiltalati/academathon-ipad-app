import SwiftUI

struct RootView: View {
    @State private var isLoggedIn = KeychainService.load() != nil

    var body: some View {
        if isLoggedIn {
            LessonListView(onLogout: { isLoggedIn = false })
        } else {
            LoginView(onLoginSuccess: { isLoggedIn = true })
        }
    }
}
