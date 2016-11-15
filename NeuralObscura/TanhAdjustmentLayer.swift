//
//  TanhAdjustmentLayer.swift
//  NeuralObscura
//
//  Created by Paul Bergeron on 11/6/16.
//  Copyright © 2016 Paul Bergeron. All rights reserved.
//

import Foundation
import MetalPerformanceShaders

class TanhAdjustmentLayer: UnaryCommandEncoder {
    init(debug: Bool = false) {
        super.init(
            delegate: TanhAdjustmentLayerDelegate(),
            debug: debug)
    }
}

class TanhAdjustmentLayerDelegate: CommandEncoderDelegate {
    private var sourceImage: MPSImage!

    init() {}

    func getDestinationImageDescriptor(sourceImage: MPSImage) -> MPSImageDescriptor {
        return MPSImageDescriptor(
            channelFormat: textureFormat,
            width: sourceImage.width,
            height: sourceImage.height,
            featureChannels: sourceImage.featureChannels)
    }
    
    
    func supplyInput(sourceImage: MPSImage, sourcePosition: Int) -> Bool {
        self.sourceImage = sourceImage
        return true
    }

    func encode(commandBuffer: MTLCommandBuffer, destinationImage: MPSImage) {
        let encoder = commandBuffer.makeComputeCommandEncoder()
        encoder.setComputePipelineState(ShaderRegistry.getOrLoad(name: "tanh_adjustment"))
        encoder.setTexture(sourceImage.texture, at: 0)
        encoder.setTexture(destinationImage.texture, at: 1)
        let threadsPerGroup = MTLSizeMake(1, 1, 1)
        let threadGroups = MTLSizeMake(destinationImage.texture.width,
                                       destinationImage.texture.height,
                                       destinationImage.texture.arrayLength)
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadsPerGroup)
        encoder.endEncoding()

        if sourceImage is MPSTemporaryImage {
            (sourceImage as! MPSTemporaryImage).readCount -= 1
        }
    }
}
