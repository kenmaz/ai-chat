import Foundation
import SwiftUI
import FoundationModels

actor ChatManager {
    private(set) var messages: [Message] = []
    private var continuation: AsyncStream<[Message]>.Continuation?
    private var session = LanguageModelSession(
        instructions: """
            You are a close friend.
            Please respond to sent messages like a real friend would - 
            sometimes friendly, sometimes emotional.
            Always respond in Japanese.
            
        """
    )
    
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
        
        let thinkingMessage = Message(text: "考え中...", isFromUser: false, isThinking: true)
        messages.append(thinkingMessage)
        continuation?.yield(messages)

        do {
            let replyText = try await generateReply(for: text)
            
            messages.removeLast()
            let botMessage = Message(text: replyText, isFromUser: false, isThinking: false)
            messages.append(botMessage)
            continuation?.yield(messages)
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            session = newSession(previousSession: session)
            let errorMessage = Message(text: "え、なんて？", isFromUser: false, isThinking: false)
            messages.append(errorMessage)
            continuation?.yield(messages)

        } catch {
            messages.removeLast()
            let errorMessage = Message(text: "エラーが発生しました: \(error.localizedDescription)", isFromUser: false, isThinking: false)
            messages.append(errorMessage)
            continuation?.yield(messages)
        }
    }
    
    private func newSession(previousSession: LanguageModelSession) -> LanguageModelSession {
      let allEntries = previousSession.transcript.entries
      var condensedEntries = [Transcript.Entry]()
      if let firstEntry = allEntries.first {
        condensedEntries.append(firstEntry)
        if allEntries.count > 1, let lastEntry = allEntries.last {
          condensedEntries.append(lastEntry)
        }
      }
      let condensedTranscript = Transcript(entries: condensedEntries)
      // Note: transcript includes instructions.
      return LanguageModelSession(transcript: condensedTranscript)
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
