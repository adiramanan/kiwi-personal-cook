import SwiftUI

@main
struct KiwiApp: App {
    @State private var appState = AppState()

    init() {
#if DEBUG
        Config.logResolvedBaseURLIfNeeded()
#endif
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isLoading {
                    // Branded splash — shown while Keychain auth check runs
                    VStack(spacing: 16) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(.kiwiGreen)
                        Text("Kiwi")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                    }
                } else if appState.isAuthenticated {
                    MainTabView()
                } else {
                    SignInView()
                }
            }
            .environment(appState)
            .task { await appState.checkAuth() }
        }
    }
}
