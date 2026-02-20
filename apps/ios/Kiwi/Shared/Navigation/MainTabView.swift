import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AppTab = .kiwi
    @State private var showScanSheet = false
    @State private var previousTab: AppTab = .kiwi

    enum AppTab: Int, Hashable {
        case kiwi
        case groceries
        case profile
        case camera
    }

    var body: some View {
        TabView(selection: cameraTabBinding) {
            Tab("Kiwi", systemImage: "diamond.fill", value: AppTab.kiwi) {
                NavigationStack {
                    ChatView()
                }
            }

            Tab("Groceries", systemImage: "circle.fill", value: AppTab.groceries) {
                NavigationStack {
                    GroceriesView()
                }
            }

            Tab("Profile", systemImage: "triangle.fill", value: AppTab.profile) {
                NavigationStack {
                    ProfileView()
                }
            }

            Tab("Scan", systemImage: "camera.fill", value: AppTab.camera) {
                Color.clear
            }
        }
        .tint(.kiwiGreen)
        .fullScreenCover(isPresented: $showScanSheet) {
            NavigationStack {
                ScanView()
            }
        }
    }

    private var cameraTabBinding: Binding<AppTab> {
        Binding(
            get: { selectedTab },
            set: { newTab in
                if newTab == .camera {
                    showScanSheet = true
                } else {
                    previousTab = selectedTab
                    selectedTab = newTab
                }
            }
        )
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
}
