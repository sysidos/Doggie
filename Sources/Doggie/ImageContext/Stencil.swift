//
//  Stencil.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2017 Susan Cheng. All rights reserved.
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
import Dispatch

@_versioned
@_fixed_layout
struct ShapeRasterizeBuffer : RasterizeBufferProtocol {
    
    @_versioned
    var stencil: UnsafeMutablePointer<Int16>
    
    @_versioned
    var width: Int
    
    @_versioned
    var height: Int
    
    @_versioned
    @inline(__always)
    init(stencil: UnsafeMutablePointer<Int16>, width: Int, height: Int) {
        self.stencil = stencil
        self.width = width
        self.height = height
    }
    
    @_versioned
    @inline(__always)
    static func + (lhs: ShapeRasterizeBuffer, rhs: Int) -> ShapeRasterizeBuffer {
        return ShapeRasterizeBuffer(stencil: lhs.stencil + rhs, width: lhs.width, height: lhs.height)
    }
    
    @_versioned
    @inline(__always)
    static func += (lhs: inout ShapeRasterizeBuffer, rhs: Int) {
        lhs.stencil += rhs
    }
}

@_versioned
@inline(__always)
func _render(_ op: Shape.RenderOperation, width: Int, height: Int, transform: SDTransform, stencil: UnsafeMutablePointer<Int16>) {
    
    let rasterizer = ShapeRasterizeBuffer(stencil: stencil, width: width, height: height)
    
    switch op {
    case let .triangle(p0, p1, p2):
        
        let q0 = p0 * transform
        let q1 = p1 * transform
        let q2 = p2 * transform
        
        if cross(q1 - q0, q2 - q0).sign == .plus {
            rasterizer.rasterize(q0, q1, q2) { _, pixel in pixel.stencil.pointee.fetchAdd(1) }
        } else {
            rasterizer.rasterize(q0, q1, q2) { _, pixel in pixel.stencil.pointee.fetchSub(1) }
        }
        
    case let .quadratic(p0, p1, p2):
        
        let q0 = p0 * transform
        let q1 = p1 * transform
        let q2 = p2 * transform
        
        if cross(q1 - q0, q2 - q0).sign == .plus {
            rasterizer.rasterize(q0, q1, q2) { barycentric, point, pixel in
                let s = 0.5 * barycentric.y + barycentric.z
                if s * s < barycentric.z {
                    pixel.stencil.pointee.fetchAdd(1)
                }
            }
        } else {
            rasterizer.rasterize(q0, q1, q2) { barycentric, point, pixel in
                let s = 0.5 * barycentric.y + barycentric.z
                if s * s < barycentric.z {
                    pixel.stencil.pointee.fetchSub(1)
                }
            }
        }
        
    case let .cubic(p0, p1, p2, v0, v1, v2):
        
        let q0 = p0 * transform
        let q1 = p1 * transform
        let q2 = p2 * transform
        
        if cross(q1 - q0, q2 - q0).sign == .plus {
            rasterizer.rasterize(q0, q1, q2) { barycentric, point, pixel in
                let u0 = barycentric.x * v0
                let u1 = barycentric.y * v1
                let u2 = barycentric.z * v2
                let v = u0 + u1 + u2
                if v.x * v.x * v.x < v.y * v.z {
                    pixel.stencil.pointee.fetchAdd(1)
                }
            }
        } else {
            rasterizer.rasterize(q0, q1, q2) { barycentric, point, pixel in
                let u0 = barycentric.x * v0
                let u1 = barycentric.y * v1
                let u2 = barycentric.z * v2
                let v = u0 + u1 + u2
                if v.x * v.x * v.x < v.y * v.z {
                    pixel.stencil.pointee.fetchSub(1)
                }
            }
        }
    }
}

extension Shape {
    
    @_versioned
    @inline(__always)
    func raster(width: Int, height: Int, stencil: inout [Int16]) -> Rect {
        
        assert(stencil.count == width * height, "incorrect size of stencil.")
        
        if stencil.count == 0 {
            return Rect()
        }
        
        let transform = self.transform
        
        var bound: Rect?
        
        stencil.withUnsafeMutableBufferPointer { stencil in
            
            if let ptr = stencil.baseAddress {
                
                let group = DispatchGroup()
                
                self.render { op in
                    
                    SDDefaultDispatchQueue.async(group: group) { _render(op, width: width, height: height, transform: transform, stencil: ptr) }
                    
                    switch op {
                    case let .triangle(p0, p1, p2):
                        
                        let q0 = p0 * transform
                        let q1 = p1 * transform
                        let q2 = p2 * transform
                        
                        bound = bound?.union(Rect.bound([q0, q1, q2])) ?? Rect.bound([q0, q1, q2])
                        
                    case let .quadratic(p0, p1, p2):
                        
                        let q0 = p0 * transform
                        let q1 = p1 * transform
                        let q2 = p2 * transform
                        
                        bound = bound?.union(Rect.bound([q0, q1, q2])) ?? Rect.bound([q0, q1, q2])
                        
                    case let .cubic(p0, p1, p2, _, _, _):
                        
                        let q0 = p0 * transform
                        let q1 = p1 * transform
                        let q2 = p2 * transform
                        
                        bound = bound?.union(Rect.bound([q0, q1, q2])) ?? Rect.bound([q0, q1, q2])
                    }
                }
                
                group.wait()
            }
        }
        
        return bound ?? Rect()
    }
}

extension ImageContext {
    
    @_versioned
    @_inlineable
    func _stencil(shape: Shape) -> (Rect, [Int16]) {
        
        let transform = shape.transform * self.transform
        
        var shape = shape
        
        if antialias {
            
            shape.transform = transform * SDTransform.scale(5)
            
            var stencil = [Int16](repeating: 0, count: width * height * 25)
            
            var bound = shape.raster(width: width * 5, height: height * 5, stencil: &stencil)
            
            bound.origin /= 5
            bound.size /= 5
            
            return (bound, stencil)
            
        } else {
            
            shape.transform = transform
            
            var stencil = [Int16](repeating: 0, count: width * height)
            
            let bound = shape.raster(width: width, height: height, stencil: &stencil)
            
            return (bound, stencil)
        }
    }
}