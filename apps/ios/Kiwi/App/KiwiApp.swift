import SwiftUI

@main
struct KiwiApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isAuthenticated {
                    MainTabView()
                } else {
                    SignInView()
                }
            }
            .environment(appState)
            .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
        }
    }
}

struct MainTabView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        TabView {
            ScanView(viewModel: ScanViewModel(
                getQuotaUseCase: GetQuotaUseCase(
                    apiClient: AppDependencies.shared.apiClient
                ),
                rateLimiter: AppDependencies.shared.rateLimiter
            ))
            .tabItem {
                Label("Scan", systemImage: "camera")
            }

            AccountView(viewModel: AccountViewModel(
                deleteAccountUseCase: DeleteAccountUseCase(
                    apiClient: AppDependencies.shared.apiClient
                ),
                appState: appState
            ))
            .tabItem {
                Label("Account", systemImage: "person.circle")
            }
        }
        .tint(.kiwiGreen)
    }
}
