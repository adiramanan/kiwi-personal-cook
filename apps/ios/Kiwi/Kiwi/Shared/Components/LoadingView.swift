import SwiftUI

struct LoadingView: View {
    let label: String

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(label)
                .font(.kiwiBody)
        }
        .padding()
        .accessibilityElement(children: .combine)
    }
}
