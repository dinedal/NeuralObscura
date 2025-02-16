//
//  MPSImageExtensionsTests.swift
//  NeuralObscura
//
//  Created by Paul Bergeron on 1/18/17.
//  Copyright © 2017 Paul Bergeron. All rights reserved.
//

import XCTest
import MetalKit
import MetalPerformanceShaders
@testable import NeuralObscura

class MPSImageExtensionsTests: CommandEncoderBaseTest {

    func testLoadFromNumpy() {
        let url = Bundle(for: type(of: self))
            .url(forResource: "test_loadFromNumpy_data", withExtension: "npy", subdirectory: "testdata")!
        let outputImg = MPSImage.loadFromNumpy(url, destinationPixelFormat: .r32Float)

        let expImg = [1.1, 2.2, 3.3, 4.4] as [Float32]

        XCTAssert(outputImg.isLossyEqual(expImg, precision: 2))
    }

    func testFloat32ToString() {
        let debug2ImagePath = Bundle.main.path(forResource: "debug2", ofType: "png")!
        let image = UIImage.init(contentsOfFile: debug2ImagePath)!
        let inputMtlTexture = ShaderRegistry.getDevice().MakeMTLTexture(uiImage: image,
                                                                        pixelFormat: .rgba32Float)

        let testImg = MPSImage(texture: inputMtlTexture, featureChannels: 3)

        let expString = "255.00 200.00 150.00 100.00 \n0.00 0.00 0.00 0.00 \n0.00 0.00 0.00 0.00 \n255.00 255.00 255.00 255.00 \n"

        XCTAssertEqual(testImg.Float32ToString(), expString)
    }

    func testFloat16ToString() {
        let debug2ImagePath = Bundle.main.path(forResource: "debug2", ofType: "png")!
        let image = UIImage.init(contentsOfFile: debug2ImagePath)!
        let inputMtlTexture = ShaderRegistry.getDevice().MakeMTLTexture(uiImage: image,
                                                                        pixelFormat: .rgba16Float)

        let testImg = MPSImage(texture: inputMtlTexture, featureChannels: 3)

        let expString = "255.00 200.00 150.00 100.00 \n0.00 0.00 0.00 0.00 \n0.00 0.00 0.00 0.00 \n255.00 255.00 255.00 255.00 \n"

        XCTAssertEqual(testImg.Float16ToString(), expString)
    }
}
