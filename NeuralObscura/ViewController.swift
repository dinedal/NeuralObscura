//
//  ViewController.swift
//  NeuralObscura
//
//  Created by Paul Bergeron on 9/15/16.
//  Copyright © 2016 Paul Bergeron. All rights reserved.
//

import UIKit
import MetalKit
import MetalPerformanceShaders

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    private var device: MTLDevice!
    private var ciContext : CIContext!
    private var textureLoader : MTKTextureLoader!
    private var commandQueue: MTLCommandQueue!
    var sourceTexture : MTLTexture? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        device = MTLCreateSystemDefaultDevice()

        guard MPSSupportsMTLDevice(device) else {
            print("Error: Metal Performance Shaders not supported on this device")
            return
        }

        ciContext = CIContext.init(mtlDevice: device)

        textureLoader = MTKTextureLoader(device: device!)

        commandQueue = device!.makeCommandQueue()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func takePicture(_ sender: AnyObject) {
        let imagePicker = UIImagePickerController()
        // If the device has a camera, take a picture, otherwise,
        // just pick from photo library
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera
        } else {
            imagePicker.sourceType = .photoLibrary
        }

        imagePicker.delegate = self

        present(imagePicker, animated: true, completion: nil)
    }

    @IBAction func takePictureFromLibrary(_ sender: AnyObject) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary

        imagePicker.delegate = self

        present(imagePicker, animated: true, completion: nil)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        imageView.image = image

        dismiss(animated: true, completion: nil)
    }

    @IBAction func doStyling(_ sender: AnyObject) {
        var image = imageView.image!.cgImage
        if (image == nil) {
            let ciImage = CIImage(image: imageView.image!)
            image = ciContext.createCGImage(ciImage!, from: ciImage!.extent)
        }

        do {
            sourceTexture = try textureLoader.newTexture(with: image!, options: [:])
        }
        catch let error as NSError {
            fatalError("Unexpected error ocurred: \(error.localizedDescription).")
        }

        //TODO: get output image by running model
        let model = CompositionModel()

        print("done")

        // Comes out flipped over x axis and oddly colored
        let ciImage = CIImage(mtlTexture: sourceTexture!)
        imageView.image = UIImage(ciImage: ciImage!)
    }

}

