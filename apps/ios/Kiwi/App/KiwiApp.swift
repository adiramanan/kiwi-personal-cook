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
                if appState.isAuthenticated {
                    MainTabView()
                } else {
                    SignInView()
                }
            }
            .environment(appState)
        }
    }
}
