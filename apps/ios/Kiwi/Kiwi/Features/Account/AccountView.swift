import SwiftUI

struct AccountView: View {
    @Environment(AppState.self) private var appState
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text("j***@icloud.com")
                            .foregroundStyle(.secondary)
                    }
                    Button("Sign Out") {
                        appState.signOut()
                    }
                }

                Section("Privacy") {
                    Link("Privacy Policy", destination: URL(string: "https://kiwi.example.com/privacy")!)
                    Text("Images are deleted immediately after processing.")
                        .font(.kiwiCaption)
                }

                Section("Danger Zone") {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Text("Delete My Account")
                    }
                }
            }
            .navigationTitle("Account")
            .alert("Delete Account", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    Task {
                        let viewModel = AccountViewModel(appState: appState)
                        await viewModel.deleteAccount()
                    }
                }
            } message: {
                Text("This will permanently delete your account.")
            }
        }
    }
}
