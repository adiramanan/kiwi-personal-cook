import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isDestructive: Bool = false

    init(_ title: String, isDestructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isDestructive = isDestructive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(KiwiTypography.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .padding(.horizontal, KiwiSpacing.xl)
                .padding(.vertical, KiwiSpacing.md)
                .background(isDestructive ? Color.kiwiDestructive : Color.kiwiGreen)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(.horizontal, KiwiSpacing.lg)
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryButton("Scan Your Fridge") {}
        PrimaryButton("Delete Account", isDestructive: true) {}
    }
}
