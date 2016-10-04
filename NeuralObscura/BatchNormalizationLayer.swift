//
//  BatchNormalizationLayer.swift
//  NeuralObscura
//
//  Created by Edward Knox on 9/27/16.
//  Copyright © 2016 Paul Bergeron. All rights reserved.
//

import Foundation
import MetalPerformanceShaders

class BatchNormalizationLayer: CommandEncoder {
    init(
        device: MTLDevice,
        channelsIn: UInt,
        beta: StyleModelData,
        gamma: StyleModelData,
        useTemporary: Bool = true) {
        super.init(
            device: device,
            delegate: BatchNormalizationLayerDelegate(
                device: device,
                channelsIn: channelsIn,
                beta: beta,
                gamma: gamma),
            useTemporary: useTemporary)
    }
}

class BatchNormalizationLayerDelegate: CommandEncoderDelegate {
    let beta: Float
    let gamma: Float
    let channelsIn: Int
    
    init(device: MTLDevice, channelsIn: UInt, beta: StyleModelData, gamma: StyleModelData) {
        self.channelsIn = Int(channelsIn)
        self.beta = beta.pointer().pointee // TODO: Reexamine this dereference
        self.gamma = gamma.pointer().pointee
    }
    
    func getDestinationImageDescriptor(sourceImage: MPSImage?) -> MPSImageDescriptor {
        return MPSImageDescriptor(
            channelFormat: textureFormat,
            width: sourceImage!.width,
            height: sourceImage!.height,
            featureChannels: sourceImage!.featureChannels)
    }
    
    func encode(commandBuffer: MTLCommandBuffer, sourceImage: MPSImage, destinationImage: MPSImage) {
        // TODO: encode batch normalization
    }
}
