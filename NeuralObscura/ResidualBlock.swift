//
//  ResidualBlock.swift
//  NeuralObscura
//
//  Created by Edward Knox on 9/25/16.
//  Copyright © 2016 Paul Bergeron. All rights reserved.
//

import Foundation
import MetalPerformanceShaders

class ResidualBlock {
    let c1, c2: MPSCNNConvolution!
    let b1, b2: BatchNormalization!
    let m: ResidualSum!
    
    /**
     * A property to keep info from init time whether we will pad input image or not for use during encode call
     */
    fileprivate var padding = true
    
    /**
     Initializes a residual block.
     
     - Parameters:
     - device: The MTLDevice on which this SlimMPSCNNConvolution filter will be used
     - layerPrefix
     - channelsIn
     - channelsOut
     - stride
     - kernelSize
     
     - Returns:
     A valid ResidualBlock object or nil, if failure.
     */
    
    
    init(device: MTLDevice, layerPrefix: String, channelsIn: UInt, channelsOut: UInt, stride: UInt, kernelSize: UInt){
        self.device = device
        
        c1 = ConvolutionLayer
    }
    
    /**
     Encode a MPSCNNKernel into a command Buffer. The operation shall proceed out-of-place.
     
     We calculate the appropriate offset as per how TensorFlow calculates its padding using input image size and stride here.
     
     This [Link](https://github.com/tensorflow/tensorflow/blob/master/tensorflow/python/ops/nn.py) has an explanation in header comments how tensorFlow pads its convolution input images.
     
     - Parameters:
     - commandBuffer: A valid MTLCommandBuffer to receive the encoded filter
     - sourceImage: A valid MPSImage object containing the source image.
     - destinationImage: A valid MPSImage to be overwritten by result image. destinationImage may not alias sourceImage
     */
    override func encode(commandBuffer: MTLCommandBuffer, sourceImage: MPSImage, destinationImage: MPSImage) {
        
        // select offset according to padding being used or not
        if(padding){
            let pad_along_height = ((destinationImage.height - 1) * strideInPixelsY + kernelHeight - sourceImage.height)
            let pad_along_width  = ((destinationImage.width - 1) * strideInPixelsX + kernelWidth - sourceImage.width)
            let pad_top = Int(pad_along_height / 2)
            let pad_left = Int(pad_along_width / 2)
            
            self.offset = MPSOffset(x: ((Int(kernelWidth)/2) - pad_left), y: (Int(kernelHeight/2) - pad_top), z: 0)
        }
        else{
            self.offset = MPSOffset(x: Int(kernelWidth)/2, y: Int(kernelHeight)/2, z: 0)
        }
        super.encode(commandBuffer: commandBuffer, sourceImage: sourceImage, destinationImage: destinationImage)
    }
    
}
