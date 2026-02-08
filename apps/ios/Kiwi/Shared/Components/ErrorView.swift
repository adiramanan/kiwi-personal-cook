import SwiftUI

struct ErrorView: View {
    let error: AppError
    let onRetry: (() -> Void)?

    init(error: AppError, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundStyle(iconColor)
                .accessibilityLabel(error.title)

            VStack(spacing: 8) {
                Text(error.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)

                Text(error.message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if error.isRetryable, let onRetry {
                Button(action: onRetry) {
                    Text("Try Again")
                        .font(.headline)
                        .frame(minWidth: 140, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(.kiwiGreen)
                .accessibilityHint("Tap to retry the operation")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var iconName: String {
        switch error {
        case .network:
            return "wifi.slash"
        case .server, .invalidData, .unknown:
            return "exclamationmark.triangle"
        case .rateLimited:
            return "clock.badge.exclamationmark"
        case .unauthorized:
            return "lock"
        }
    }

    private var iconColor: Color {
        switch error {
        case .rateLimited:
            return .kiwiOrange
        case .unauthorized:
            return .red
        default:
            return .secondary
        }
    }
}

#Preview("Network Error") {
    ErrorView(error: .network) {
        print("Retry tapped")
    }
}

#Preview("Rate Limited") {
    ErrorView(error: .rateLimited)
}
