//
//  ContentView.swift
//  ChatGPT-Test
//
//  Created by Simeon Shaffar on 2/28/25.
//

import SwiftUI
import Combine

enum MessageSender {
    case user
    case gpt
}

struct ChatMessage {
    let id: String
    let message: String
    let dateCreated: Date
    let sender: MessageSender
}

extension ChatMessage {
    static let sampleMessages: [ChatMessage] = [
        ChatMessage(id: UUID().uuidString, message: "What is 9 + 10",
                    dateCreated: .now, sender: .user),
        ChatMessage(id: UUID().uuidString, message: "Are you fucking retarded",
                    dateCreated: .now, sender: .gpt),
        ChatMessage(id: UUID().uuidString, message: "No I am asking for a friend",
                    dateCreated: .now, sender: .user),
        ChatMessage(id: UUID().uuidString, message: "Ok sure, how about I teach you to color in between the lines while you are at it.",
                    dateCreated: .now, sender: .gpt),
    ]
}

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var messages: [ChatMessage] = []
    
    @State private var currentMessage: String = ""
    
    let service = OpenAIService()
    @State private var cancellables: Set<AnyCancellable> = .init()
    
    var body: some View {
        VStack {
            ScrollView {
                LazyVStack {
                    ForEach(messages, id: \.id) { chatMessage in
                        messageView(chatMessage: chatMessage)
                    } //ForEach sampleMessage
                } //LazyVStack
                .padding(.top, 50)
                .padding()
            } //ScrollView
            
            .ignoresSafeArea(edges: [.top])
            
            HStack {
                TextField("Yell at ChatGPT", text: $currentMessage)
                    .padding(.leading, 5)
                    .padding(5)
                    .background {
                        RoundedRectangle(cornerRadius: 15) .stroke(lineWidth: 2)
                            .foregroundStyle(Color.gray.opacity(0.2))
                    }
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up") .resizable().scaledToFit() .frame(width: 15)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Circle().fill(.blue))
                }
            } //HStack
            .padding(.horizontal)
            .padding(.bottom, 8)
            .border(.red)
        } //Outer VStack
        
    } //body
    
    func messageView(chatMessage: ChatMessage) -> some View {
        HStack {
            if chatMessage.sender == .user {
                Spacer()
            }
            
            VStack(alignment: chatMessage.sender == .user ? .trailing : .leading, spacing: 5) {
                switch chatMessage.sender {
                case .user:
                    Text("You") .font(.subheadline) .bold()
                        .foregroundStyle(.gray)
                        .padding(.trailing, 10)
                case .gpt:
                    Text("ChatGPT") .font(.subheadline) .bold()
                        .foregroundStyle(.gray)
                        .padding(.leading, 10)
                }
                Text(chatMessage.message) .font(.subheadline)
                    .foregroundStyle(chatMessage.sender == .user ? .white : .primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background {
                        Rectangle() .fill(chatMessage.sender == .user ? .blue : .gray)
                            .opacity(chatMessage.sender == .user ? 1 : 0.2)
                    }
                    .cornerRadius(15)
            } //VStack
            
            if chatMessage.sender == .gpt {
                Spacer()
            }
        } //HStack
    } //messageView
    
    func sendMessage() {
        let userMessage = ChatMessage(id: UUID().uuidString, message: currentMessage, dateCreated: .now, sender: .user)
        withAnimation { messages.append(userMessage) }
        
        service.sendMessage(content: currentMessage).sink { completion in
            //Handle error
        } receiveValue: { response in
            let gptMessage = ChatMessage(id: UUID().uuidString, message: response.choices.first!.message.content, dateCreated: .now, sender: .gpt)
            withAnimation { messages.append(gptMessage) }
        } //sendMessage
        .store(in: &cancellables)
        
        currentMessage = ""
    } //sendMessage
}

#Preview {
    ContentView()
}
