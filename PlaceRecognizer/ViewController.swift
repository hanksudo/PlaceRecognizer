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

class ViewController: UIViewController, UIGestureRecognizerDelegate, AVCapturePhotoCaptureDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var session: AVCaptureSession!
    var camera: AVCaptureDevice!
    var input: AVCaptureDeviceInput!
    var output: AVCapturePhotoOutput!
    var textView: UITextView!
    var imageView: UIImageView!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var swipeGesture: UISwipeGestureRecognizer!
    var tapGesture: UITapGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    
    @IBAction func goCamera(_ sender: UIButton) {
        swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(closeCamera))
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(takePhoto))
        tapGesture.delegate = self
        swipeGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
        self.view.addGestureRecognizer(swipeGesture)
        
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
        
        previewLayer = AVCaptureVideoPreviewLayer.init(session: session)
        previewLayer.frame = self.view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        
        self.view.layer.addSublayer(previewLayer)
        
        session.startRunning()
        
        textView = UITextView(frame: CGRect(x:10, y:50, width:self.view.frame.width - 20, height:500))
        textView.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 1, alpha: 0.3)
        textView.text = ""
        textView.isSelectable = false
        self.view.addSubview(textView)
    }
    @IBAction func selectPhoto(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = .savedPhotosAlbum
        self.present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        imageView = UIImageView(frame: CGRect(x:10, y:50, width:self.view.frame.width - 20, height:500))
        imageView.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 1, alpha: 0.3)
        self.view.addSubview(imageView)
        
        textView = UITextView(frame: CGRect(x:10, y:50, width:self.view.frame.width - 20, height:500))
        textView.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 1, alpha: 0.3)
        textView.text = ""
        textView.isSelectable = false
        self.view.addSubview(textView)
        
        imageView.image = info[UIImagePickerControllerEditedImage] as? UIImage
        self.dismiss(animated: true, completion: nil)
        
        self.recognize(image: imageView.image!)
    }

    @objc func closeCamera() {
        textView.removeFromSuperview()
        previewLayer.removeFromSuperlayer()
        self.view.removeGestureRecognizer(tapGesture)
        self.view.removeGestureRecognizer(swipeGesture)
        
        session.stopRunning()
        for output in session.outputs {
            session.removeOutput(output)
        }
        for input in session.inputs {
            session.removeInput(input)
        }
        session = nil
        camera = nil
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

