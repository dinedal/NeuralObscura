//
//  MTLPixelFormat.swift
//  NeuralObscura
//
//  Created by Paul Bergeron on 11/7/16.
//  Copyright © 2016 Paul Bergeron. All rights reserved.
//
import MetalPerformanceShaders

extension MTLPixelFormat {
    var channelCount: Int {
        switch self {
        case .rgba8Unorm:
            return 4
        case .r8Unorm:
            return 1
        case .rgba32Float:
            return 4
        case .rgba16Float:
            return 4
        case .r32Float:
            return 1
        case .r16Float:
            return 1
        default:
            fatalError("Unknown MTLPixelFormat: \(self)")
        }
    }

    var sizeOfDataType: Int {
        switch self {
        case .rgba8Unorm:
            return MemoryLayout<UInt8>.size
        case .r8Unorm:
            return MemoryLayout<UInt8>.size
        case .rgba32Float:
            return MemoryLayout<Float32>.size
        case .r32Float:
            return MemoryLayout<Float32>.size
        case .r16Float:
            return MemoryLayout<UInt16>.size
        case .rgba16Float:
            return MemoryLayout<UInt16>.size
        default:
            fatalError("Unknown MTLPixelFormat: \(self)")
        }
    }

    func featureChannelsToSlices(_ featureChannels: Int) -> Int {
        return Int(ceil(Float(featureChannels) / Float(self.channelCount)))
    }

    func typedSize(width: Int, height: Int) -> Int {
        return width * height * self.channelCount
    }

    func featureChannels(_ arrayLength: Int) -> Int {
        return arrayLength * self.channelCount
    }

    func bytesPerRow(_ width: Int) -> Int {
        return width * self.channelCount * self.sizeOfDataType
    }
}
