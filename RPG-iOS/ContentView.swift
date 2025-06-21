import SwiftUI

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    let timestamp = Date()
}

struct ContentView: View {
    @State private var chatManager = ChatManager()
    @State private var newMessageText = ""
    @State private var messages: [Message] = []
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(messages) { message in
                            HStack {
                                if message.isFromUser {
                                    Spacer()
                                    MessageBubble(message: message)
                                        .id(message.id)
                                } else {
                                    MessageBubble(message: message)
                                        .id(message.id)
                                    Spacer()
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .onChange(of: messages.count) {
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            HStack {
                TextField("メッセージを入力", text: $newMessageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        sendMessage()
                    }
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
                .disabled(newMessageText.isEmpty)
            }
            .padding()
        }
        .navigationTitle("チャット")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            for await updatedMessages in await chatManager.messagesStream {
                messages = updatedMessages
            }
        }
    }
    
    func sendMessage() {
        let messageText = newMessageText
        newMessageText = ""
        
        Task {
            await chatManager.sendMessage(messageText)
        }
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        Text(message.text)
            .padding(10)
            .background(message.isFromUser ? Color.blue : Color.gray.opacity(0.3))
            .foregroundColor(message.isFromUser ? .white : .primary)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(message.isFromUser ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}
