import SwiftUI

struct AccountView: View {
    @Bindable var viewModel: AccountViewModel
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            List {
                // Account Section
                Section("Account") {
                    HStack {
                        Image(systemName: "person.circle")
                            .font(.title2)
                            .foregroundStyle(.kiwiGreen)
                        VStack(alignment: .leading) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(maskedEmail)
                                .font(.body)
                        }
                    }
                    .padding(.vertical, 4)

                    Button(action: {
                        appState.signOut()
                    }) {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.primary)
                    }
                    .frame(minHeight: 44)
                    .accessibilityHint("Signs you out of your account")
                }

                // Privacy Section
                Section("Privacy") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("How we handle your data", systemImage: "hand.raised")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("We never store your fridge photos. Images are processed and immediately deleted. Only your account info and usage data are stored.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                // Danger Zone
                Section {
                    Button(role: .destructive, action: {
                        viewModel.showDeleteConfirmation = true
                    }) {
                        HStack {
                            if viewModel.isDeleting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Label("Delete My Account", systemImage: "trash")
                        }
                        .frame(minHeight: 44)
                    }
                    .disabled(viewModel.isDeleting)
                    .accessibilityHint("Permanently deletes your account and all associated data")
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("This action is permanent and cannot be undone. All your data will be deleted.")
                }
            }
            .navigationTitle("Account")
            .alert("Delete Account?", isPresented: $viewModel.showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        try? await viewModel.deleteAccount()
                    }
                }
            } message: {
                Text("This will permanently delete your account and all associated data. This cannot be undone.")
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK") { viewModel.error = nil }
            } message: {
                if let error = viewModel.error {
                    Text(error.message)
                }
            }
        }
    }

    private var maskedEmail: String {
        // Masked email display - in production this would come from the user profile
        "j***@icloud.com"
    }
}
