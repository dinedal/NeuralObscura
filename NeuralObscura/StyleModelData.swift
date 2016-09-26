//
//  StyleModel.swift
//  NeuralObscura
//
//  Created by Paul Bergeron on 9/20/16.
//  Copyright © 2016 Paul Bergeron. All rights reserved.
//

import Foundation
import MetalPerformanceShaders

class StyleModelData {
    private var fd: CInt!
    private var hdr: UnsafeMutableRawPointer!
    private var ptr: UnsafeMutablePointer<Float>!
    private var fileSize: UInt64 = 0
    let modelName: String
    let rawFileName: String

    init(modelName: String, rawFileName: String) {
        self.modelName = modelName
        self.rawFileName = rawFileName

        loadRawFile(rawFileName: self.rawFileName)
    }

    private func loadRawFile(rawFileName: String) {
        let path = Bundle.main.path(forResource: rawFileName, ofType: "dat", inDirectory: self.modelName + "_model_data")

        assert(path != nil, "Error: failed to find file \(rawFileName)")

        do {
            let attr = try FileManager.default.attributesOfItem(atPath: path!)

            if let fsize = attr[FileAttributeKey.size] as? NSNumber {
                fileSize = fsize.uint64Value
            } else {
                print("Failed to get a size attribute from path: \(path)")
            }
        } catch {
            print("Error: \(error)")
        }

        // open file descriptors in read-only mode to parameter files
        let fd = open( path!, O_RDONLY, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH)

        assert(fd != -1, "Error: failed to open file at \""+path!+"\"  errno = \(errno)\n")

        let hdr = mmap(nil, Int(fileSize), PROT_READ, MAP_FILE | MAP_SHARED, fd, 0)

        print("Opened: \(path!) (\(fileSize))")

        let floatCount = Int(fileSize) / MemoryLayout<Float>.size
        ptr = hdr!.bindMemory(to: Float.self, capacity: floatCount)
        if ptr == UnsafeMutablePointer<Float>(bitPattern: -1) {
            print("Error: mmap failed, errno = \(errno)")
        }
    }

    deinit{
        print("deinit \(self) \(modelName) \(rawFileName)")

        if let hdr = hdr {
            let result = munmap(hdr, Int(fileSize))
            assert(result == 0, "Error: munmap failed, errno = \(errno)")
        }
        if let fd = fd {
            close(fd)
        }
    }

    func pointer() -> UnsafeMutablePointer<Float> {
        return ptr
    }

}
