import SwiftUI

struct LoadingView: View {
    let label: String

    init(_ label: String = "Loading...") {
        self.label = label
    }

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.2)

            Text(label)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
    }
}

#Preview {
    LoadingView("Identifying ingredients...")
}
