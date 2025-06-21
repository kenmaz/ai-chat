import Foundation
import SwiftUI
import FoundationModels

actor ChatManager {
    private(set) var messages: [Message] = []
    private var continuation: AsyncStream<[Message]>.Continuation?
    private let session = LanguageModelSession()
    
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
            let replyText = try await generateReply(for: text)
            let botMessage = Message(text: replyText, isFromUser: false)
            messages.append(botMessage)
            continuation?.yield(messages)
        } catch {
            let errorMessage = Message(text: "エラーが発生しました: \(error.localizedDescription)", isFromUser: false)
            messages.append(errorMessage)
            continuation?.yield(messages)
        }
    }
    
    private func generateReply(for text: String) async throws -> String {
        let res = try await session.respond(to: text)
        return res.content
    }
    
    func clearMessages() {
        messages.removeAll()
        continuation?.yield(messages)
    }
}
