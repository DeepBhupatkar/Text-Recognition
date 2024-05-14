//
//  ContentView.swift
//  TextRecognitionApp
//
//  Created by DEEP BHUPATKAR on 14/05/24.
//

import SwiftUI
import Vision
import PhotosUI

struct ContentView: View {
    
    @State private var uiImage: UIImage? = nil
    @State private var recognizedText: String = ""
    @State private var showCamera = false
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        VStack {
            ScrollView {
                Text(recognizedText.isEmpty ? "" : recognizedText)
            }
            .scrollDismissesKeyboard(.interactively)
            .padding()
            
            
            HStack {     PhotosPicker("Select an image", selection: $selectedItem, matching: .images)
                    .onChange(of: selectedItem) {
                        Task {
                            if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                                uiImage = UIImage(data: data)
                            }
                            print("Failed to load the image")
                        }
                    }
                
                
                Button("Take a photo") {
                    self.showCamera.toggle()
                    self.uiImage = UIImage(named: "screenshot")
                    //if self.uiImage != nil {
                    //  processImage(uiImage: self.uiImage!)
                    //}
                }.buttonStyle(.borderedProminent)
                    .fullScreenCover(isPresented: self.$showCamera) {
                        accessCameraView(selectedImage: self.$uiImage)
                    }
            }.buttonStyle(.borderedProminent) .padding()
            
            Button(action: {
                if self.uiImage != nil {
                    processImage(uiImage: self.uiImage!)
                }
            }) {
                Label("Start Coverting To text", systemImage: "play")
                    .padding(12)
                    .foregroundColor(.white)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
            }
            
            
        }
        .padding()
    }
    
    
    func processImage(uiImage : UIImage) -> Void {
        
        //Steps to covert the image to text
        
        //Step 1 Converting UIImage to CgImage
        guard let cgImage = uiImage.cgImage else{
            
            print("Failed To Covert to CGImage")
            return
        }
        
        //Step 2 Creating the Image Handler
        
        let imageRequestHandler = VNImageRequestHandler(cgImage:cgImage)
        
        //Step 3 Making the Request for coverting the CGImage Into Text
        
        let request = VNRecognizeTextRequest{request, error in
            
            //Step 4 to covert Request To Observation
            
            guard let results = request.results as? [VNRecognizedTextObservation],
                  error == nil
            else {
                print("Error Found while converting to VNRecognizedTextObservation")
                recognizedText = "Something went wrong"
                return
            }
            
            //Step 5 Use the result (Combining the each observation(result) in one object)
            let outputText = results.compactMap{ observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            //Step 6 Make Sure when you set the text it should be in UI Thread / main thread
            // UI = outputText
            
            DispatchQueue.main.async{
                recognizedText = outputText
            }
            
        }
        
        //Step 7 Perform Request.
        // Send the requests to the request handler.
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try imageRequestHandler.perform([request])
            } catch let error as NSError {
                print("Failed to perform image request: \(error)")
                //                self.presentAlert("Image Request Failed", error: error)
                return
            }
        }
        
        
        
    }
}


struct accessCameraView: UIViewControllerRepresentable {
    
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var isPresented
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        imagePicker.delegate = context.coordinator
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(picker: self)
    }
}

// Coordinator will help to preview the selected image in the View.
class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var picker: accessCameraView
    
    init(picker: accessCameraView) {
        self.picker = picker
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let selectedImage = info[.originalImage] as? UIImage else { return }
        self.picker.selectedImage = selectedImage
        self.picker.isPresented.wrappedValue.dismiss()
    }
}

#Preview {
    ContentView()
}
