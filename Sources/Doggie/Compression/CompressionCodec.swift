//
//  CompressionCodec.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2018 Susan Cheng. All rights reserved.
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

import Foundation

public protocol CompressionCodec {
    
    func process(_ source: UnsafeBufferPointer<UInt8>, _ callback: (UnsafeBufferPointer<UInt8>) -> Void) throws
    
    func final(_ callback: (UnsafeBufferPointer<UInt8>) -> Void) throws
}

extension CompressionCodec {
    
    @_inlineable
    public func process<S : UnsafeBufferProtocol, C : RangeReplaceableCollection>(_ source: S, _ output: inout C) throws where S.Element == UInt8, C.Element == UInt8 {
        try process(source) { output.append(contentsOf: $0) }
    }
    
    @_inlineable
    public func process<S : UnsafeBufferProtocol>(_ source: S, _ callback: (UnsafeBufferPointer<UInt8>) -> Void) throws where S.Element == UInt8 {
        try source.withUnsafeBufferPointer { try process($0, callback) }
    }
}

extension CompressionCodec {
    
    @_inlineable
    public func process<C : RangeReplaceableCollection>(_ source: Data, _ output: inout C) throws where C.Element == UInt8 {
        try process(source) { output.append(contentsOf: $0) }
    }
    
    @_inlineable
    public func process(_ source: Data, _ callback: (UnsafeBufferPointer<UInt8>) -> Void) throws {
        try source.withUnsafeBytes { try process(UnsafeBufferPointer(start: $0, count: source.count), callback) }
    }
}

extension CompressionCodec {
    
    @_inlineable
    public func final<C : RangeReplaceableCollection>(_ output: inout C) throws where C.Element == UInt8 {
        try final { output.append(contentsOf: $0) }
    }
}

extension CompressionCodec {
    
    @_inlineable
    public func process(_ source: Data) throws -> Data {
        
        var result = Data(capacity: source.count)
        
        try self.process(source, &result)
        try self.final(&result)
        
        return result
    }
}
