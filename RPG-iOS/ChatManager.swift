import Foundation
import SwiftUI

actor ChatManager {
    private(set) var messages: [Message] = []
    private var continuation: AsyncStream<[Message]>.Continuation?
    
    var messagesStream: AsyncStream<[Message]> {
        AsyncStream { continuation in
            self.continuation = continuation
            continuation.yield(messages)
        }
    }
    
    func sendMessage(_ text: String) async {
        guard !text.isEmpty else { return }
        
        let userMessage = Message(text: text, isFromUser: true)
        messages.append(userMessage)
        continuation?.yield(messages)

        do {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            let replyText = await generateReply(for: text)
            let botMessage = Message(text: replyText, isFromUser: false)
            messages.append(botMessage)
            continuation?.yield(messages)
        } catch {
            let errorMessage = Message(text: "エラーが発生しました: \(error.localizedDescription)", isFromUser: false)
            messages.append(errorMessage)
            continuation?.yield(messages)
        }
    }
    
    private func generateReply(for text: String) async -> String {
        return "「\(text)」を受信しました"
    }
    
    func clearMessages() {
        messages.removeAll()
        continuation?.yield(messages)
    }
}
