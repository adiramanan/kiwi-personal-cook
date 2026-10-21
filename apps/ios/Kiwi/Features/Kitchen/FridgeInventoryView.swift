import SwiftUI

struct FridgeInventoryView: View {
    @Environment(KitchenStore.self) private var kitchen
    @State private var showScan = false
    @State private var editing: FridgeItem?
    @State private var adding = false

    var body: some View {
        List {
            Section {
                KitchenHeading(eyebrow: "A little less waste", title: "Inside your fridge", subtitle: "Keep your ingredients up to date. Meal ideas can wait until you're hungry.")
                    .listRowBackground(Color.clear).listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 20, trailing: 0))
                KitchenAction(title: "Scan your fridge", icon: "camera") { showScan = true }
                    .listRowBackground(Color.clear).listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0))
            }
            if kitchen.inventory.isEmpty {
                ContentUnavailableView("A fresh start", systemImage: "refrigerator", description: Text("Scan a shelf or add ingredients by hand. You'll review everything before it's saved."))
                    .listRowBackground(Color.clear)
            } else {
                Section("Available ingredients · \(kitchen.inventory.count)") {
                    ForEach(kitchen.inventory) { item in
                        Button { editing = item } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.kitchenGreen)
                                Text(item.name).foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "pencil").foregroundStyle(.secondary).font(.caption)
                            }.frame(minHeight: 44)
                        }.accessibilityLabel("Edit \(item.name)")
                    }
                    .onDelete { offsets in
                        let ids = offsets.map { kitchen.inventory[$0].id }
                        Task { _ = await kitchen.saveInventory([], removing: ids) }
                    }
                }
                Section {
                    Text("Ingredients stay here until you remove them. Cooking a meal doesn't automatically change your fridge.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Fridge").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button { adding = true } label: { Image(systemName: "plus") }.accessibilityLabel("Add ingredient manually")
        }
        .refreshable { await kitchen.refresh() }
        .sheet(isPresented: $showScan) { NavigationStack { FridgeCaptureView() } }
        .sheet(isPresented: $adding) { NavigationStack { IngredientEditor(item: FridgeItem(name: "")) } }
        .sheet(item: $editing) { item in NavigationStack { IngredientEditor(item: item) } }
    }
}

struct IngredientEditor: View {
    @Environment(KitchenStore.self) private var kitchen
    @Environment(\.dismiss) private var dismiss
    @State var item: FridgeItem
    @State private var saving = false
    var body: some View {
        Form {
            TextField("Ingredient name", text: $item.name).textInputAutocapitalization(.sentences)
            Text("Use a simple name, like eggs or spinach. Quantities and expiry dates aren't tracked yet.").font(.footnote).foregroundStyle(.secondary)
            if let error = kitchen.error { Text(error).foregroundStyle(.red).font(.footnote) }
        }
        .navigationTitle("Ingredient").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(saving) }
            ToolbarItem(placement: .confirmationAction) {
                Button(saving ? "Saving…" : "Save") {
                    saving = true
                    Task {
                        if await kitchen.saveInventory([item]) { dismiss() }
                        saving = false
                    }
                }.disabled(saving || item.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || item.name.count > 100)
            }
        }.interactiveDismissDisabled(saving)
    }
}
