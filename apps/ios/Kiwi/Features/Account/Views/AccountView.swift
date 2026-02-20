import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = AccountViewModel()

    var body: some View {
        List {
            Section("Dietary Preferences") {
                Label("Coming soon", systemImage: "fork.knife")
                    .foregroundStyle(.secondary)
            }

            Section("Account") {
                Button("Sign Out") {
                    appState.signOut()
                }
            }

            Section("Privacy") {
                Label("Images are processed and immediately deleted", systemImage: "lock.shield")
                    .font(KiwiTypography.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button(role: .destructive) {
                    viewModel.showDeleteConfirmation = true
                } label: {
                    HStack {
                        if viewModel.isDeleting {
                            ProgressView()
                                .padding(.trailing, KiwiSpacing.sm)
                        }
                        Text("Delete My Account")
                    }
                }
                .disabled(viewModel.isDeleting)
            } header: {
                Text("Danger Zone")
            }
        }
        .navigationTitle("Profile")
        .alert("Delete Account?", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await viewModel.deleteAccount()
                        appState.signOut()
                    } catch {
                        viewModel.error = error as? APIError ?? .unknown
                    }
                }
            }
        } message: {
            Text("This will permanently delete your account and all associated data. This action cannot be undone.")
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK") { viewModel.error = nil }
        } message: {
            if let error = viewModel.error {
                Text(error.userMessage)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environment(AppState())
}
