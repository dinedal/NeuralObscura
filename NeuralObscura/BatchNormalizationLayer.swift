//
//  BatchNormalizationLayer.swift
//  NeuralObscura
//
//  Created by Edward Knox on 9/27/16.
//  Copyright © 2016 Paul Bergeron. All rights reserved.
//

import Foundation
import MetalPerformanceShaders

class BatchNormalizationLayer: UnaryCommandEncoder {
    private let beta: ParameterBuffer
    private let gamma: ParameterBuffer
    private let mean: ParameterBuffer
    private let stddev: ParameterBuffer
    private let useTemporary: Bool
    private var consumerCount: Int = 0
    private var input: AnyCommandEncoder<MPSImage>!
    private var outputMemoId: Int?
    private var outputMemo: MPSImage?
    
    init(beta: ParameterBuffer,
         gamma: ParameterBuffer,
         mean: ParameterBuffer,
         stddev: ParameterBuffer,
         useTemporary: Bool = false) {
        self.useTemporary = useTemporary
        self.beta = beta
        self.gamma = gamma
        self.mean = mean
        self.stddev = stddev
    }
    
    func chain(_ input: AnyCommandEncoder<MPSImage>) -> AnyCommandEncoder<MPSImage> {
        self.input = input
        input.registerConsumer()
        return AnyCommandEncoder<MPSImage>(self)
    }
    
    func registerConsumer() {
        consumerCount += 1
    }
    
    func forward(commandBuffer: MTLCommandBuffer) -> MPSImage {
        if outputMemoId != nil && outputMemoId! == commandBuffer.hash {
            return outputMemo!
        } else {
            let sourceImage = input.forward(commandBuffer: commandBuffer)
            let destinationImage = self.destinationImage(sourceImage: sourceImage, commandBuffer: commandBuffer)
            encode(commandBuffer: commandBuffer, sourceImage: sourceImage, destinationImage: destinationImage)
            outputMemoId = commandBuffer.hash
            outputMemo = destinationImage
            return outputMemo!
        }
    }
    
    private func encode(commandBuffer: MTLCommandBuffer, sourceImage: MPSImage, destinationImage: MPSImage) {
        let betaBuf = ShaderRegistry.getDevice()
            .makeBuffer(
                bytes: beta.pointer,
                length: beta.length,
                options: MTLResourceOptions.cpuCacheModeWriteCombined)
        let gammaBuf = ShaderRegistry.getDevice()
            .makeBuffer(
                bytes: gamma.pointer,
                length: gamma.length,
                options: MTLResourceOptions.cpuCacheModeWriteCombined)
        let meanBuf = ShaderRegistry.getDevice()
            .makeBuffer(
                bytes: mean.pointer,
                length: mean.length,
                options: MTLResourceOptions.cpuCacheModeWriteCombined)
        let stddevBuf = ShaderRegistry.getDevice()
            .makeBuffer(
                bytes: stddev.pointer,
                length: stddev.length,
                options: MTLResourceOptions.cpuCacheModeWriteCombined)
        
        let encoder = commandBuffer.makeComputeCommandEncoder()
        encoder.setComputePipelineState(ShaderRegistry.getOrLoad(name: "batch_normalization"))
        encoder.setTexture(sourceImage.texture, at: 0)
        encoder.setTexture(destinationImage.texture, at: 1)
        encoder.setBuffer(gammaBuf, offset: 0, at: 2)
        encoder.setBuffer(betaBuf, offset: 0, at: 3)
        encoder.setBuffer(meanBuf, offset: 0, at: 4)
        encoder.setBuffer(stddevBuf, offset: 0, at: 5)
        let threadsPerGroup = MTLSizeMake(1, 1, 1)
        let threadGroups = MTLSizeMake(sourceImage.texture.width,
                                       sourceImage.texture.height,
                                       sourceImage.texture.arrayLength)
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadsPerGroup)
        encoder.endEncoding()

        if let image = sourceImage as? MPSTemporaryImage {
            image.readCount -= 1
        }
    }
    
    private func destinationImage(sourceImage: MPSImage, commandBuffer: MTLCommandBuffer) -> MPSImage {
        let textureDesc = MTLTextureDescriptor()
        textureDesc.arrayLength = sourceImage.texture.arrayLength
        textureDesc.height = sourceImage.height
        textureDesc.width = sourceImage.width
        textureDesc.textureType = .type2DArray
        textureDesc.usage = MTLTextureUsage(rawValue:
            MTLTextureUsage.shaderWrite.rawValue | MTLTextureUsage.shaderRead.rawValue)
        textureDesc.pixelFormat = .rgba16Float
        
        if useTemporary {
            let img = MPSTemporaryImage.init(commandBuffer: commandBuffer, textureDescriptor: textureDesc)
            img.readCount = consumerCount
            return img
        } else {
            let texture = ShaderRegistry.getDevice().makeTexture(descriptor: textureDesc)
            return MPSImage.init(texture: texture, featureChannels: max(4, sourceImage.featureChannels))
        }
    }
}
