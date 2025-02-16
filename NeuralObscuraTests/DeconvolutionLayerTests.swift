//
//  DeconvolutionLayerTests.swift
//  NeuralObscura
//
//  Created by Edward Knox on 11/4/16.
//  Copyright © 2016 Paul Bergeron. All rights reserved.
//

import Foundation
import XCTest
import MetalKit
import MetalPerformanceShaders
@testable import NeuralObscura

class DeconvolutionLayerTests: CommandEncoderBaseTest {

    func testInterpixelStride() {
        let testImg1 = device.MakeMPSImage(width: 2,
                                           height: 2,
                                           featureChannels: 4,
                                           pixelFormat: MTLPixelFormat.rgba32Float,
                                           values: [[1,2,3,4], [4,3,2,1],
                                                    [3,4,2,1], [2,1,3,4]])

        let outputImg = device.MakeMPSImage(width: 4,
                                            height: 4,
                                            featureChannels: 4,
                                            pixelFormat: MTLPixelFormat.rgba32Float,
                                            values: [[0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0],
                                                     [0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0],
                                                     [0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0],
                                                     [0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0]])

        var s = UInt(2)
        let interpixelStride = ShaderRegistry.getDevice().makeBuffer(
            bytes: &s,
            length: MemoryLayout<UInt>.size,
            options: MTLResourceOptions.cpuCacheModeWriteCombined)

        /* Create our CommandEncoder*/
        let encoder = commandBuffer.makeComputeCommandEncoder()
        encoder.setComputePipelineState(ShaderRegistry.getOrLoad(name: "deconvolution_interpixel_stride"))
        encoder.setTexture(testImg1.texture, at: 0)
        encoder.setTexture(outputImg.texture, at: 1)
        encoder.setBuffer(interpixelStride, offset: 0, at: 2)
        let threadsPerGroup = MTLSizeMake(1, 1, 1)
        let threadGroups = MTLSizeMake(outputImg.texture.width,
                                       outputImg.texture.height, 1)
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadsPerGroup)
        encoder.endEncoding()
        /* Run our test */
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        let expImg = device.MakeMPSImage(width: 4,
                                         height: 4,
                                         featureChannels: 4,
                                         pixelFormat: MTLPixelFormat.rgba32Float,
                                         values: [[1,2,3,4], [0,0,0,0], [4,3,2,1], [0,0,0,0],
                                                  [0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0],
                                                  [3,4,2,1], [0,0,0,0], [2,1,3,4], [0,0,0,0],
                                                  [0,0,0,0], [0,0,0,0], [0,0,0,0], [0,0,0,0]])

        /* Verify the result */
        XCTAssertEqual(outputImg, expImg)
    }

    func testIdentityNoPadding() {
        let testImg = device.MakeMPSImage(width: 2, height: 2, values: [1, 0,
                                                                        0, 1] as [Float32])
        
        /* Create our CommandEncoder */
        let w_pb = MemoryParameterBuffer([0, 0, 0,
                                          0, 1, 0,
                                          0, 0, 0])
        let b_pb = MemoryParameterBuffer(0)
        let deconv = DeconvolutionLayer(
            kernelSize: 3,
            channelsIn: 1,
            channelsOut: 1,
            w: w_pb,
            b: b_pb,
            relu: false,
            padding: 0,
            debug: true)
        
        let expImg = device.MakeMPSImage(width: 4,
                                         height: 4,
                                         pixelFormat: testTextureFormatR,
                                         values: [0, 0, 0, 0,
                                                  0, 1, 0, 0,
                                                  0, 0, 1, 0,
                                                  0, 0, 0, 0] as [Float32])
        
        /* Run our test */
        let outputImg = deconv.execute(commandBuffer: commandBuffer, sourceImage: testImg)
        
        /* Verify the result */
        XCTAssertEqual(outputImg, expImg)
    }

    func testIdentityHalfPadding() {
        let testImg = device.MakeMPSImage(width: 4,
                                          height: 4,
                                          values: [0, 0, 0, 0,
                                                   0, 1, 0, 0,
                                                   0, 0, 1, 0,
                                                   0, 0, 0, 0] as [Float32])
        
        /* Create our CommandEncoder */
        let w_pb = MemoryParameterBuffer([0, 0, 0,
                                          0, 1, 0,
                                          0, 0, 0])
        let b_pb = MemoryParameterBuffer(0)
        let deconv = DeconvolutionLayer(
            kernelSize: 3,
            channelsIn: 1,
            channelsOut: 1,
            w: w_pb,
            b: b_pb,
            relu: false,
            padding: 1,
            debug: true)
        
        let expImg = device.MakeMPSImage(width: 4,
                                         height: 4,
                                         pixelFormat: testTextureFormatR,
                                         values: [0, 0, 0, 0,
                                                  0, 1, 0, 0,
                                                  0, 0, 1, 0,
                                                  0, 0, 0, 0] as [Float32])
        
        /* Run our test */
        let outputImg = deconv.execute(commandBuffer: commandBuffer, sourceImage: testImg)
        
        /* Verify the result */
        XCTAssertEqual(outputImg, expImg)
    }
    
    func testIdentityFullPadding() {
        let testImg = device.MakeMPSImage(width: 6,
                                          height: 6,
                                          values: [0, 0, 0, 0, 0, 0,
                                                   0, 0, 0, 0, 0, 0,
                                                   0, 0, 1, 0, 1, 0,
                                                   0, 0, 0, 1, 0, 0,
                                                   0, 0, 0, 0, 0, 0,
                                                   0, 0, 0, 0, 0, 0] as [Float32])
        /* Create our CommandEncoder */
        let w_pb = MemoryParameterBuffer([0, 0, 0,
                                          0, 1, 0,
                                          0, 0, 0])
        let b_pb = MemoryParameterBuffer(0)
        let deconv = DeconvolutionLayer(
            kernelSize: 3,
            channelsIn: 1,
            channelsOut: 1,
            w: w_pb,
            b: b_pb,
            relu: false,
            padding: 2,
            debug: true)
        
        let expImg = device.MakeMPSImage(width: 4,
                                         height: 4,
                                         pixelFormat: testTextureFormatR,
                                         values: [0, 0, 0, 0,
                                                  0, 1, 0, 1,
                                                  0, 0, 1, 0,
                                                  0, 0, 0, 0] as [Float32])
        
        /* Run our test */
        let outputImg = deconv.execute(commandBuffer: commandBuffer, sourceImage: testImg)
        
        /* Verify the result */
        XCTAssertEqual(outputImg, expImg)
    }
    
    func testSumHalfPaddingNonUnitStride() {
        let testImg = device.MakeMPSImage(width: 4,
                                          height: 4,
                                          values: [0, 0, 0, 0,
                                                   0, 1, 0, 0,
                                                   0, 0, 1, 0,
                                                   0, 0, 0, 0] as [Float32])
        
        /* Create our CommandEncoder */
        let w_pb = MemoryParameterBuffer([1, 1, 1,
                                          1, 1, 1,
                                          1, 1, 1])
        let b_pb = MemoryParameterBuffer(0)
        let deconv = DeconvolutionLayer(
            kernelSize: 3,
            channelsIn: 1,
            channelsOut: 1,
            w: w_pb,
            b: b_pb,
            relu: false,
            padding: 1,
            stride: 2,
            debug: true)
        
        let expImg = device.MakeMPSImage(width: 7,
                                         height: 7,
                                         pixelFormat: testTextureFormatR,
                                         values: [0, 0, 0, 0, 0, 0, 0,
                                                  0, 1, 1, 1, 0, 0, 0,
                                                  0, 1, 1, 1, 0, 0, 0,
                                                  0, 1, 1, 2, 1, 1, 0,
                                                  0, 0, 0, 1, 1, 1, 0,
                                                  0, 0, 0, 1, 1, 1, 0,
                                                  0, 0, 0, 0, 0, 0, 0] as [Float32])
        
        /* Run our test */
        let outputImg = deconv.execute(commandBuffer: commandBuffer, sourceImage: testImg)
        
        /* Verify the result */
        XCTAssertEqual(outputImg, expImg)
    }

}
