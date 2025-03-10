//
//  CameraView.swift
//  ChatGPT-Test
//
//  Created by Simeon Shaffar on 3/10/25.
//

import SwiftUI

struct CameraView: View {
    @State private var vm = CameraViewModel()
    
    var body: some View {
        GeometryReader { geo in
            CameraPreview(cameraViewModel: $vm, frame: geo.frame(in: .local))
                .onAppear() {
                    vm.requestAccessAndSetup()
                }
        } .ignoresSafeArea()
        
    }
}

#Preview {
    CameraView()
}
