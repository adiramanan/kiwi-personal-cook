import SwiftUI

struct FamilyView: View {
    @Environment(KitchenStore.self) private var kitchen
    @State private var adding = false
    @State private var editing: FamilyMember?
    @State private var deleting: FamilyMember?
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                KitchenHeading(eyebrow: "Everyone at the table", title: "Different goals.\nOne good meal.", subtitle: "Tell us what each person loves, avoids, and is working toward. We'll find a shared meal with portions for each of you.")
                if kitchen.members.isEmpty {
                    ContentUnavailableView("Who are we cooking for?", systemImage: "person.2", description: Text("Start with yourself, then add the people you cook for. You can change everything later."))
                }
                ForEach(kitchen.members) { member in
                    Button { editing = member } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(String(member.name.prefix(1)).uppercased()).font(.title3.weight(.semibold)).frame(width: 48, height: 48)
                                    .background(Color.kitchenGreen.opacity(0.1), in: Circle()).accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(member.name).font(.headline).foregroundStyle(.primary)
                                    Text(member.goalLabel).font(.subheadline).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                            }
                            Text(member.dietLabel).font(.subheadline).foregroundStyle(.secondary)
                            if !member.allergies.isEmpty { Label("Avoids \(member.allergies.joined(separator: ", "))", systemImage: "exclamationmark.shield").font(.caption).foregroundStyle(.primary) }
                            if let calories = member.calorieTarget { Text("Meal target · \(calories) kcal").font(.caption).foregroundStyle(.secondary) }
                            if let protein = member.proteinTarget { Text("Meal target · \(protein.formatted()) g protein").font(.caption).foregroundStyle(.secondary) }
                        }.kitchenSurface()
                    }.buttonStyle(.plain)
                    .contextMenu { Button("Remove member", role: .destructive) { deleting = member } }
                }
                KitchenAction(title: "Add family member", icon: "person.badge.plus") { adding = true }
                    .disabled(kitchen.members.count >= 20)
                Text("Restrictions always come first. Goals guide portions and suggestions; tastes help us choose between suitable meals.")
                    .font(.footnote).foregroundStyle(.secondary)
            }.padding(24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Family").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            NavigationLink { ProfileView(onAccountDeleted: { kitchen.clearLocalAccountData() }) } label: { Image(systemName: "gearshape") }.accessibilityLabel("Account settings")
        }
        .refreshable { await kitchen.refresh() }
        .sheet(isPresented: $adding) { NavigationStack { FamilyMemberEditor(member: FamilyMember(), creating: true) } }
        .sheet(item: $editing) { member in NavigationStack { FamilyMemberEditor(member: member, creating: false) } }
        .confirmationDialog("Remove this family member?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
            Button("Remove member", role: .destructive) { if let deleting { Task { await kitchen.deleteMember(deleting) } }; deleting = nil }
        }
    }
}

struct FamilyMemberEditor: View {
    @Environment(KitchenStore.self) private var kitchen
    @Environment(\.dismiss) private var dismiss
    @State var member: FamilyMember
    let creating: Bool
    @State private var calories: String
    @State private var protein: String
    @State private var saving = false
    @State private var confirmDelete = false

    init(member: FamilyMember, creating: Bool) {
        _member = State(initialValue: member)
        self.creating = creating
        _calories = State(initialValue: member.calorieTarget.map(String.init) ?? "")
        _protein = State(initialValue: member.proteinTarget.map { $0.formatted(.number.grouping(.never)) } ?? "")
    }
    private var validTargets: Bool {
        let c = calories.trimmingCharacters(in: .whitespaces)
        let p = protein.trimmingCharacters(in: .whitespaces)
        return (c.isEmpty || Int(c).map { (100...3000).contains($0) } == true) &&
            (p.isEmpty || Double(p.replacingOccurrences(of: ",", with: ".")).map { (1...250).contains($0) } == true)
    }
    var body: some View {
        Form {
            Section("At the table") { TextField("Name", text: $member.name).textContentType(.givenName) }
            Section {
                Picker("Dietary pattern", selection: $member.diet) {
                    Text("No restriction").tag("unrestricted")
                    Text("Vegetarian").tag("vegetarian")
                    Text("Vegan").tag("vegan")
                    Text("Pescatarian").tag("pescatarian")
                }
                preferenceField("Allergies", hint: "e.g. peanut, sesame", keyPath: \.allergies)
                preferenceField("Other restrictions", hint: "e.g. no pork", keyPath: \.restrictions)
            } header: { Text("Must avoid") } footer: { Text("These take priority over preferences and goals. Check labels and recipe suitability before cooking.") }
            Section {
                preferenceField("Loved ingredients", hint: "e.g. spinach, paneer", keyPath: \.likes)
                preferenceField("Disliked ingredients", hint: "e.g. mushroom", keyPath: \.dislikes)
                preferenceField("Favorite cuisines", hint: "e.g. Indian, Thai", keyPath: \.cuisines)
                Picker("Spice", selection: $member.spice) {
                    Text("Mild").tag("mild"); Text("Medium").tag("medium"); Text("Hot").tag("hot")
                }
            } header: { Text("What tastes good") } footer: { Text("Separate ingredients and cuisines with commas.") }
            Section {
                Picker("Dietary goal", selection: $member.goal) {
                    Text("Balanced eating").tag("balanced")
                    Text("Weight management").tag("weightManagement")
                    Text("Muscle gain").tag("muscleGain")
                }
                LabeledContent("Calories per meal") { TextField("Optional kcal", text: $calories).keyboardType(.numberPad).multilineTextAlignment(.trailing) }
                LabeledContent("Protein per meal") { TextField("Optional grams", text: $protein).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                if !validTargets { Text("Enter 100–3,000 kcal and 1–250 g protein, or leave targets blank.").font(.footnote).foregroundStyle(.red) }
            } header: { Text("Your goals, your way") } footer: {
                Text("Targets are optional and chosen by you. Kiwi uses them to suggest portions, with estimated nutrition. It doesn't prescribe a diet or track your daily intake.")
            }
            if let error = kitchen.error { Section { Text(error).font(.footnote).foregroundStyle(.red) } }
            if !creating {
                Section { Button("Remove member", role: .destructive) { confirmDelete = true } }
            }
        }
        .navigationTitle(creating ? "Add a person" : "Edit preferences").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(saving) }
            ToolbarItem(placement: .confirmationAction) {
                Button(saving ? "Saving…" : "Save") {
                    member.name = member.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    for path in [\FamilyMember.allergies, \FamilyMember.restrictions, \FamilyMember.likes, \FamilyMember.dislikes, \FamilyMember.cuisines] {
                        member[keyPath: path] = member[keyPath: path].filter { !$0.isEmpty }
                    }
                    member.calorieTarget = Int(calories.trimmingCharacters(in: .whitespaces))
                    member.proteinTarget = Double(protein.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
                    saving = true
                    Task { if await kitchen.saveMember(member, creating: creating) { dismiss() }; saving = false }
                }.disabled(saving || !validTargets || member.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || member.name.count > 100)
            }
        }.interactiveDismissDisabled(saving)
        .confirmationDialog("Remove \(member.name)?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Remove member", role: .destructive) {
                saving = true
                Task {
                    await kitchen.deleteMember(member)
                    if !kitchen.members.contains(where: { $0.id == member.id }) { dismiss() }
                    saving = false
                }
            }
        }
    }
    private func preferenceField(_ title: String, hint: String, keyPath: WritableKeyPath<FamilyMember, [String]>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline.weight(.medium))
            TextField(hint, text: Binding(get: { member[keyPath: keyPath].joined(separator: ", ") }, set: { text in
                // Preserve a trailing separator while typing by retaining empty entries in the draft.
                member[keyPath: keyPath] = text.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            }), axis: .vertical).font(.body).textInputAutocapitalization(.never)
        }
    }
}
