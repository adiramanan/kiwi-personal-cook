import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.kiwiHeadline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.kiwiPrimary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .frame(minHeight: 44)
        .accessibilityLabel(title)
    }
}
