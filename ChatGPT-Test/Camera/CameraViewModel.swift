//
//  CameraViewModel.swift
//  ChatGPT-Test
//
//  Created by Simeon Shaffar on 3/10/25.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    @Binding var cameraViewModel: CameraViewModel
    let frame: CGRect
    
    func makeUIView(context: Context) -> UIView {
        let view = UIViewType(frame: frame)
        cameraViewModel.preview = AVCaptureVideoPreviewLayer(session: cameraViewModel.session)
        cameraViewModel.preview.frame = frame
        cameraViewModel.preview.videoGravity = .resizeAspectFill
        
        view.layer.addSublayer(cameraViewModel.preview)
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        cameraViewModel.preview.frame = frame
        cameraViewModel.preview.connection?.videoRotationAngle = UIDevice.current.orientation.videoRotationAngle
    }
}

@Observable
class CameraViewModel: NSObject {
    enum PhotoCaptureState {
        case notStarted
        case processing
        case finished(Data)
    }
    
    var session = AVCaptureSession()
    var preview = AVCaptureVideoPreviewLayer()
    var output = AVCapturePhotoOutput()
    
    var photoData: Data? {
        switch photoCaptureState {
        case .notStarted, .processing:
            nil
        case .finished(let data):
            data
        }
    }
    
    var hasPhoto: Bool { photoData != nil }
    
    private(set) var photoCaptureState: PhotoCaptureState = .notStarted
    
    func requestAccessAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { didAllowAccess in
                self.setup()
            }
        case .authorized:
            self.setup()
        default:
            print("Not authorized to use the camera")
        }
    }
    
    private func setup() {
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSession.Preset.photo
        
        do {
            guard let device = AVCaptureDevice.default(for: .video) else { return }
            let input = try AVCaptureDeviceInput(device: device)
            
            guard session.canAddInput(input) else { return }
            session.addInput(input)
            
            guard session.canAddOutput(output) else { return }
            session.addOutput(output)
            
            session.commitConfiguration()
            
            Task(priority: .background) {
                self.session.startRunning()
                await MainActor.run {
                    self.preview.connection?.videoRotationAngle = UIDevice.current.orientation.videoRotationAngle
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func takePhoto() {
        guard case .notStarted = photoCaptureState else { return }
        
        output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        withAnimation {
            self.photoCaptureState = .processing
        }
    }
    
    func retakePhoto() {
        Task(priority: .background) {
            self.session.startRunning()
            self.photoCaptureState = .notStarted
        }
    }
}


extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
        if let error {
            print(error.localizedDescription)
        }
        
        guard let imageData = photo.fileDataRepresentation() else { return }
        
        guard let provider = CGDataProvider(data: imageData as CFData) else { return }
        guard let cgImage = CGImage(jpegDataProviderSource: provider, decode: nil,
                                    shouldInterpolate: true, intent: .defaultIntent) else { return }
        
        Task(priority: .background) {
            self.session.stopRunning()
            await MainActor.run {
                let image = UIImage(cgImage: cgImage, scale: 1, orientation: .up)
                let imageData = image.jpegData(compressionQuality: 0)
                print("CameraViewModel compressed the hell out of an image: \(imageData)")
                
                withAnimation {
                    if let imageData {
                        self.photoCaptureState = .finished(imageData)
                    } else {
                        print("Failed to process the image as a UIImage from a cgImage")
                    }
                }
            }
        }
    }
}
