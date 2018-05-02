//
//  ViewController.swift
//  PlaceRecognizer
//
//  Created by Hank Wang on 2018/5/3.
//  Copyright © 2018 hanksudo. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    var session: AVCaptureSession!
    var camera: AVCaptureDevice!
    var input: AVCaptureDeviceInput!
    var output: AVCapturePhotoOutput!
    var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let recognizeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 120, height: 50))
        recognizeButton.backgroundColor = UIColor.black
        recognizeButton.layer.masksToBounds = true
        recognizeButton.setTitle("Recognize", for: .normal)
        recognizeButton.layer.cornerRadius = 20.0
        recognizeButton.layer.position = CGPoint(x: self.view.bounds.width/2, y:self.view.bounds.height-50)
        recognizeButton.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
        self.view.addSubview(recognizeButton)
        
        // MARK: recognize result
        
        textView = UITextView(frame: CGRect(x:10, y:50, width:self.view.frame.width - 20, height:500))
        textView.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 1, alpha: 0.3)
        textView.text = ""
        textView.isSelectable = false
        self.view.addSubview(textView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        session = AVCaptureSession()
        
        camera = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .back).devices.first
        
        input = try! AVCaptureDeviceInput.init(device: camera)
        output = AVCapturePhotoOutput()
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer.init(session: session)
        previewLayer.frame = self.view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        
        self.view.layer.addSublayer(previewLayer)
        
        session.startRunning()
    }

    @objc func takePhoto(sender: UIButton) {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        settings.isAutoStillImageStabilizationEnabled = true
        settings.isHighResolutionPhotoEnabled = false
        
        output.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let imageData = photo.fileDataRepresentation()
        self.recognize(image: UIImage(data: imageData!)!)
    }
    func recognize(image: UIImage) {

        let model = try! VNCoreMLModel(for: GoogLeNetPlaces().model)
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Results Error")
            }
            
            var result = ""
            for classification in results {
                result += "\(classification.identifier) \(classification.confidence * 100)％\n"
            }
            print(result)
            self.textView.text = result
        }
        let handler = VNImageRequestHandler(cgImage: image.cgImage!)
        
        guard (try? handler.perform([request])) != nil else {
            fatalError("Error on model")
        }
    }
}

