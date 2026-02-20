import Foundation

@Observable
final class ChatViewModel {
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isLoading: Bool = false

    struct ChatMessage: Identifiable {
        let id = UUID()
        let text: String
        let isFromUser: Bool
        let timestamp: Date
    }

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messages.append(ChatMessage(text: text, isFromUser: true, timestamp: .now))
        inputText = ""
        isLoading = true

        // Placeholder: simulate a response
        Task {
            try? await Task.sleep(for: .seconds(1))
            messages.append(ChatMessage(
                text: "I'm Kiwi, your cooking assistant! Take a photo of your fridge using the camera tab, and I'll suggest recipes for you.",
                isFromUser: false,
                timestamp: .now
            ))
            isLoading = false
        }
    }
}
