import SwiftUI

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.scenePhase) private var scenePhase
    @State private var kitchen = KitchenStore.makeDefault()

    var body: some View {
        TabView {
            Tab("Cook", systemImage: "fork.knife") {
                NavigationStack { CookHomeView() }
            }
            Tab("Fridge", systemImage: "refrigerator") {
                NavigationStack { FridgeInventoryView() }
            }
            Tab("Family", systemImage: "person.2") {
                NavigationStack { FamilyView() }
            }
        }
        .tint(.kitchenGreen)
        .environment(kitchen)
        .task { await kitchen.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await kitchen.refresh() } }
        }
        .onChange(of: appState.isAuthenticated) { _, authenticated in
            if !authenticated { kitchen.clearLocalAccountData() }
        }
        .alert("Couldn't finish", isPresented: Binding(get: { kitchen.error != nil }, set: { if !$0 { kitchen.error = nil } })) {
            Button("OK") { kitchen.error = nil }
        } message: { Text(kitchen.error ?? "") }
    }
}
