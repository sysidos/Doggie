//
//  GPUContextRendering.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2019 Susan Cheng. All rights reserved.
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

#if canImport(CoreImage) || canImport(QuartzCore)

private let context = CIContext()

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
extension GPUContext {
    
    public func makeImage() -> CGImage? {
        return context.createCGImage(image, from: CGRect(x: 0, y: 0, width: width, height: width))
    }
    
    public func makeImage(format: CIFormat, colorSpace: CGColorSpace?) -> CGImage? {
        return context.createCGImage(image, from: CGRect(x: 0, y: 0, width: width, height: width), format: format, colorSpace: colorSpace)
    }
    
    public func makeImage(format: CIFormat, colorSpace: CGColorSpace?, deferred: Bool) -> CGImage? {
        return context.createCGImage(image, from: CGRect(x: 0, y: 0, width: width, height: width), format: format, colorSpace: colorSpace, deferred: deferred)
    }
}

#endif
