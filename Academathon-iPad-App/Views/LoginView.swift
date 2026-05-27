import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    var onLoginSuccess: () -> Void

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView {
                VStack {
                    Spacer(minLength: 60)

                    // Card
                    VStack(alignment: .leading, spacing: 0) {

                        // Logo + heading
                        VStack(alignment: .center, spacing: 12) {
                            Image("AppLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 72, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: 16))

                            Text("Welcome back")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(Theme.textPrimary)

                            Text("Sign in to your Academathon account")
                                .font(.subheadline)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 32)

                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundStyle(Theme.textPrimary)

                            TextField("you@example.com", text: $viewModel.email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(Theme.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.radiusMd)
                                        .stroke(Theme.border, lineWidth: 1.5)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd))
                        }

                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundStyle(Theme.textPrimary)

                            SecureField("••••••••", text: $viewModel.password)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(Theme.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.radiusMd)
                                        .stroke(Theme.border, lineWidth: 1.5)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd))
                        }
                        .padding(.top, 16)

                        // Error message
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 12)
                        }

                        // Sign In button
                        Button {
                            Task { await viewModel.login() }
                        } label: {
                            Group {
                                if viewModel.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .foregroundStyle(.white)
                            .background(
                                viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty
                                    ? Theme.accentLight
                                    : Theme.accent
                            )
                            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMd))
                        }
                        .disabled(viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty)
                        .padding(.top, 24)
                    }
                    .padding(36)
                    .background(Theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusXl))
                    .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 4)
                    .frame(maxWidth: 440)
                    .padding(.horizontal, 24)

                    Spacer(minLength: 60)
                }
                .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height)
            }
        }
        .onChange(of: viewModel.isLoggedIn) { _, newValue in
            if newValue { onLoginSuccess() }
        }
    }
}
