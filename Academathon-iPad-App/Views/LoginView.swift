import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    var onLoginSuccess: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                Text("Academathon")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text("Tutor Whiteboard")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 16) {
                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()

                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.callout)
                    .multilineTextAlignment(.center)
            }

            Button {
                Task { await viewModel.login() }
            } label: {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Text("Sign In")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isLoading || viewModel.email.isEmpty || viewModel.password.isEmpty)

            Spacer()
        }
        .padding(40)
        .frame(maxWidth: 400)
        .frame(maxWidth: .infinity)
        .onChange(of: viewModel.isLoggedIn) { _, newValue in
            if newValue { onLoginSuccess() }
        }
    }
}
