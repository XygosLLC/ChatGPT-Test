//
//  CameraView.swift
//  ChatGPT-Test
//
//  Created by Simeon Shaffar on 3/10/25.
//

import SwiftUI

struct CameraView: View {
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
                } //withAnimation
            } //onEnded
    } //pressGesture
}

#Preview {
    CameraView()
}
