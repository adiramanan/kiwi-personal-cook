import SwiftUI

struct ChatView: View {
    @State private var viewModel = ChatViewModel()

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.messages.isEmpty {
                emptyState
            } else {
                messageList
            }

            inputBar
        }
        .navigationTitle("Kiwi")
    }

    private var emptyState: some View {
        VStack(spacing: KiwiSpacing.lg) {
            Spacer()
            Image(systemName: "leaf.fill")
                .font(.system(size: 56))
                .foregroundStyle(.kiwiGreen)
                .accessibilityHidden(true)

            Text("Welcome to Kiwi")
                .font(KiwiTypography.title2)
                .fontWeight(.bold)

            Text("Your personal cooking assistant. Ask me anything about cooking, or scan your fridge to get recipe ideas!")
                .font(KiwiTypography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, KiwiSpacing.xxl)
            Spacer()
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: KiwiSpacing.md) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    if viewModel.isLoading {
                        HStack {
                            ProgressView()
                                .padding(.horizontal, KiwiSpacing.lg)
                            Spacer()
                        }
                    }
                }
                .padding(KiwiSpacing.lg)
            }
            .onChange(of: viewModel.messages.count) {
                if let last = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: KiwiSpacing.md) {
            TextField("Ask Kiwi...", text: $viewModel.inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .padding(KiwiSpacing.md)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Button {
                viewModel.sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.kiwiGreen)
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, KiwiSpacing.lg)
        .padding(.vertical, KiwiSpacing.sm)
        .background(.bar)
    }
}

private struct MessageBubble: View {
    let message: ChatViewModel.ChatMessage

    var body: some View {
        HStack {
            if message.isFromUser { Spacer(minLength: 60) }

            Text(message.text)
                .font(KiwiTypography.body)
                .padding(KiwiSpacing.md)
                .background(message.isFromUser ? Color.kiwiGreen : Color(.systemGray5))
                .foregroundStyle(message.isFromUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            if !message.isFromUser { Spacer(minLength: 60) }
        }
    }
}

#Preview {
    NavigationStack {
        ChatView()
    }
}
