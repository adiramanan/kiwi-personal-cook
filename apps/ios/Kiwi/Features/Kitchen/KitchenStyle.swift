import SwiftUI

extension Color {
    static let kitchenGreen = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.62, green: 0.82, blue: 0.67, alpha: 1)
            : UIColor(red: 0.16, green: 0.34, blue: 0.24, alpha: 1)
    })
    static let kitchenActionFill = Color(red: 0.16, green: 0.34, blue: 0.24)
}
struct KitchenSurface: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))
    }
}
extension View {
    func kitchenSurface() -> some View { modifier(KitchenSurface()) }
}
struct KitchenAction: View {
    let title: String
    var icon: String = "sparkles"
    var busy = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if busy { ProgressView().tint(.white) } else { Image(systemName: icon) }
                Text(title).font(.headline)
            }
            .frame(maxWidth: .infinity).frame(minHeight: 52)
            .foregroundStyle(.white).background(Color.kitchenActionFill, in: Capsule())
        }
        .buttonStyle(.plain).disabled(busy)
    }
}
struct KitchenHeading: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow.uppercased()).font(.caption.weight(.semibold)).tracking(2).foregroundStyle(.secondary)
            Text(title).font(.largeTitle.weight(.semibold)).fontDesign(.serif).fixedSize(horizontal: false, vertical: true)
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }
}
struct KitchenBadge: View {
    let text: String
    var body: some View {
        Text(text).font(.caption.weight(.medium)).padding(.horizontal, 10).padding(.vertical, 6)
            .background(Color.kitchenGreen.opacity(0.10), in: Capsule())
    }
}

extension ShapeStyle where Self == Color {
    static var kitchenGreen: Color { .kitchenGreen }
}
