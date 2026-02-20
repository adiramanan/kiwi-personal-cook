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
        }
    }
}
