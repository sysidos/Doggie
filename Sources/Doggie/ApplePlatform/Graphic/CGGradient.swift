//
//  CGGradient.swift
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

#if canImport(CoreGraphics)

extension CGGradient {
    
    public convenience init?<C>(colorSpace: AnyColorSpace, stops: [GradientStop<C>]) {
        
        guard let cgColorSpace = colorSpace.cgColorSpace else { return nil }
        let stops = stops.map { $0.convert(to: colorSpace) }
        
        let range = 0...colorSpace.numberOfComponents
        
        let components = stops.flatMap { stop in range.lazy.map { CGFloat(stop.color.component($0)) } }
        let locations = stops.map { CGFloat($0.offset) }
        
        self.init(colorSpace: cgColorSpace, colorComponents: components, locations: locations, count: stops.count)
    }
    
    public convenience init?<Model, C>(colorSpace: ColorSpace<Model>, stops: [GradientStop<C>]) {
        self.init(colorSpace: AnyColorSpace(colorSpace), stops: stops)
    }
}

#endif
