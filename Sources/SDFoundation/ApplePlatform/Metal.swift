//
//  Metal.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2020 Susan Cheng. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#if canImport(Metal)

import Metal

@available(macOS 10.11, iOS 8.0, tvOS 9.0, *)
extension MTLDevice {
    
    public func makeBuffer<T>(_ buffer: MappedBuffer<T>, options: MTLResourceOptions = []) -> MTLBuffer? {
        var box = MappedBuffer<T>._Box(ref: buffer.base)
        let length = (buffer.count * MemoryLayout<T>.stride).align(Int(getpagesize()))
        guard length != 0 else { return nil }
        return self.makeBuffer(bytesNoCopy: buffer.base.address, length: length, options: options, deallocator: { _, _ in box.ref = nil })
    }
}

@available(macOS 10.11, iOS 8.0, tvOS 9.0, *)
extension MTLComputeCommandEncoder {
    
    public func setBuffer<T>(_ buffer: MappedBuffer<T>, offset: Int, index: Int) {
        self.setBuffer(self.device.makeBuffer(buffer), offset: offset, index: index)
    }
}

#endif