import SwiftUI

struct ErrorView: View {
    let title: String
    let message: String
    let systemImage: String
    var retryAction: (() -> Void)?

    init(
        title: String = "Something went wrong",
        message: String,
        systemImage: String = "exclamationmark.triangle",
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.retryAction = retryAction
    }

    var body: some View {
        VStack(spacing: KiwiSpacing.lg) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(title)
                .font(KiwiTypography.title3)
                .fontWeight(.semibold)

            Text(message)
                .font(KiwiTypography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, KiwiSpacing.xl)

            if let retryAction {
                PrimaryButton("Try Again", action: retryAction)
                    .padding(.top, KiwiSpacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    ErrorView(message: "No internet connection.") {
        print("Retry tapped")
    }
}
