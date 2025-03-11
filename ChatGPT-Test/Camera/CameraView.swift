//
//  CameraView.swift
//  ChatGPT-Test
//
//  Created by Simeon Shaffar on 3/10/25.
//

import SwiftUI
import Combine

struct CameraView: View {
    @Environment(\.dismiss) var dismiss
    
    let service: OpenAIService
    @Binding var cancellables: Set<AnyCancellable>
    @Binding var messages: [ChatMessage]
    
    @State private var vm = CameraViewModel()
    
    @State private var isHolding: Bool = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                CameraPreview(cameraViewModel: $vm, frame: geo.frame(in: .local))
                    .onAppear() {
                        vm.requestAccessAndSetup()
                    }
                
                VStack {
                    Spacer()
                    
                    button
                        .onChange(of: vm.hasPhoto) {
                            withAnimation { dismiss() }
                            
                            Task(priority: .background) {
                                if let imageData = vm.photoData {
                                    sendImage(imageData: imageData)
                                } //if let imageData
                            } //BackgroundTask
                        } //onChange
                    
                } //VStack
                
            } //ZStack
            
        } .ignoresSafeArea()
        
    }
    
    
    var button: some View {
        ZStack {
            Circle() .fill(.white) .frame(width: isHolding ? 80 : 55, height: isHolding ? 80 : 55)
            
            Circle() .stroke(.white, lineWidth: 5) .frame(width: 70, height: 70)
                .padding(20)
        } //ZStack
        .padding(.bottom, 50)
        .gesture(pressGesture)
    }
    
    var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                withAnimation(.easeOut(duration: 0.1)) {
                    if !isHolding {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        isHolding = true
                    }
                } //withAnimation
            } //onChanged
            .onEnded { _ in
                withAnimation(.easeOut(duration: 0.15)) {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    isHolding = false
                    
                    if case .notStarted = vm.photoCaptureState {
                        vm.takePhoto()
                        
                    } else {
                        vm.retakePhoto()
                    }
                } //withAnimation
            } //onEnded
    } //pressGesture
    
    
    func sendImage(imageData: Data) {
//        print("CameraView found imageData: \(imageData)")
        let text = "Please explain what is going on in this image"
        
        messages.append(ChatMessage(id: UUID().uuidString, message: text, dateCreated: .now, sender: .user))
        
        service.sendImage(text: text, imageData: imageData).sink { completion in
            //Handle error
            print("CameraView sendImage error: \(completion)")
        } receiveValue: { response in
            withAnimation {
                let message = response.choices[0].message
                messages.append(ChatMessage(id: UUID().uuidString, message: message.content, dateCreated: .now, sender: .gpt))
//                print("CameraView recieved response from GPT \(message)")
            } //withAnimation
        } //sendMessage
        .store(in: &cancellables)
        
    } //sendImage
    
    
}

#Preview {
    CameraView(service: OpenAIService(), cancellables: .constant([]), messages: .constant([]))
}
