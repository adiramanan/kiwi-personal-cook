import SwiftUI

struct ErrorView: View {
    let title: String
    let message: String
    let retryTitle: String?
    let retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text(title)
                .font(.kiwiTitle)
            Text(message)
                .font(.kiwiBody)
                .multilineTextAlignment(.center)
            if let retryTitle, let retryAction {
                PrimaryButton(title: retryTitle, action: retryAction)
            }
        }
        .padding()
        .accessibilityElement(children: .combine)
    }
}
