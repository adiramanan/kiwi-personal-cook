import SwiftUI

@main
struct KiwiApp: App {
    @State private var appState = AppState()

    init() {
#if DEBUG
        Config.logResolvedBaseURLIfNeeded()
#endif
    }

    private var previewColorScheme: ColorScheme? {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--kitchen-ui-tests"),
           ProcessInfo.processInfo.arguments.contains("--dark-mode") { return .dark }
#endif
        return nil
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
                    MainTabView().id(appState.sessionToken)
                } else {
                    SignInView()
                }
            }
            .environment(appState)
            .preferredColorScheme(previewColorScheme)
            .task { await appState.checkAuth() }
        }
    }
}
