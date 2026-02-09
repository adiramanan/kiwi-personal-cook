import SwiftUI

@main
struct KiwiApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
    }
}

private struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainTabView()
            } else {
                SignInView()
            }
        }
    }
}

private struct MainTabView: View {
    var body: some View {
        TabView {
            ScanView()
                .tabItem {
                    Label("Scan", systemImage: "camera.viewfinder")
                }
            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person.circle")
                }
        }
    }
}
