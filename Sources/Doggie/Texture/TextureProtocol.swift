//
//  TextureProtocol.swift
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

public enum ResamplingAlgorithm {
    
    case none
    case linear
    case cosine
    case cubic
    case hermite(Double, Double)
    case mitchell(Double, Double)
    case lanczos(UInt)
}

extension ResamplingAlgorithm {
    
    @inlinable
    public static var `default` : ResamplingAlgorithm {
        return .linear
    }
}

public enum WrappingMode {
    
    case none
    case clamp
    case `repeat`
    case mirror
}

public protocol TextureProtocol {
    
    associatedtype RawPixel
    
    associatedtype Pixel : ScalarMultiplicative where Pixel.Scalar: BinaryFloatingPoint & FloatingMathProtocol
    
    var width: Int { get }
    
    var height: Int { get }
    
    var pixels: MappedBuffer<RawPixel> { get }
    
    var resamplingAlgorithm: ResamplingAlgorithm { get set }
    
    var horizontalWrappingMode: WrappingMode { get set }
    
    var verticalWrappingMode: WrappingMode { get set }
    
    mutating func setOrientation(_ orientation: ImageOrientation)
    
    func transposed() -> Self
    
    func verticalFlipped() -> Self
    
    func horizontalFlipped() -> Self
    
    func map<P>(_ transform: (RawPixel) throws -> P) rethrows -> Texture<P>
    
    func pixel(_ point: Point) -> Pixel
    
    func withUnsafeBufferPointer<R>(_ body: (UnsafeBufferPointer<RawPixel>) throws -> R) rethrows -> R
    
    mutating func withUnsafeMutableBufferPointer<R>(_ body: (inout UnsafeMutableBufferPointer<RawPixel>) throws -> R) rethrows -> R
    
    func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R
    
    mutating func withUnsafeMutableBytes<R>(_ body: (UnsafeMutableRawBufferPointer) throws -> R) rethrows -> R
}

extension TextureProtocol {
    
    @inlinable
    public var option: MappedBufferOption {
        return pixels.option
    }
}

@usableFromInline
protocol _TextureProtocolImplement: TextureProtocol {
    
    init(width: Int, height: Int, pixels: MappedBuffer<RawPixel>, resamplingAlgorithm: ResamplingAlgorithm)
    
    func read_source(_ x: Int, _ y: Int) -> Pixel
}

extension _TextureProtocolImplement {
    
    @inlinable
    public func map<P>(_ transform: (RawPixel) throws -> P) rethrows -> Texture<P> {
        
        var texture = try Texture<P>(width: width, height: height, pixels: pixels.map(transform), resamplingAlgorithm: resamplingAlgorithm)
        
        texture.horizontalWrappingMode = self.horizontalWrappingMode
        texture.verticalWrappingMode = self.verticalWrappingMode
        
        return texture
    }
}

extension _TextureProtocolImplement {
    
    @inlinable
    public mutating func setOrientation(_ orientation: ImageOrientation) {
        
        switch orientation {
        case .up, .upMirrored, .down, .downMirrored: break
        case .leftMirrored, .left, .rightMirrored, .right: self = self.transposed()
        }
        
        guard pixels.count != 0 else { return }
        
        let width = self.width
        let height = self.height
        
        switch orientation {
        case .up, .leftMirrored: break
        case .right, .upMirrored:
            
            self.withUnsafeMutableBufferPointer {
                
                guard let buffer = $0.baseAddress else { return }
                
                var buf1 = buffer
                var buf2 = buffer + width - 1
                
                for _ in 0..<width >> 1 {
                    Swap(height, buf1, width, buf2, width)
                    buf1 += 1
                    buf2 -= 1
                }
            }
            
        case .left, .downMirrored:
            
            self.withUnsafeMutableBufferPointer {
                
                guard let buffer = $0.baseAddress else { return }
                
                var buf1 = buffer
                var buf2 = buffer + width * (height - 1)
                
                for _ in 0..<height >> 1 {
                    Swap(width, buf1, 1, buf2, 1)
                    buf1 += width
                    buf2 -= width
                }
            }
            
        case .down, .rightMirrored:
            
            self.withUnsafeMutableBufferPointer {
                guard let buffer = $0.baseAddress else { return }
                Swap($0.count >> 1, buffer, 1, buffer + $0.count - 1, -1)
            }
        }
    }
}

extension _TextureProtocolImplement {
    
    @inlinable
    public func transposed() -> Self {
        
        if pixels.count == 0 {
            
            var texture = Self(width: height, height: width, pixels: [], resamplingAlgorithm: resamplingAlgorithm)
            
            texture.horizontalWrappingMode = self.horizontalWrappingMode
            texture.verticalWrappingMode = self.verticalWrappingMode
            
            return texture
        }
        
        var copy = pixels
        pixels.withUnsafeBufferPointer { source in copy.withUnsafeMutableBufferPointer { destination in Transpose(height, width, source.baseAddress!, 1, destination.baseAddress!, 1) } }
        
        var texture = Self(width: height, height: width, pixels: copy, resamplingAlgorithm: resamplingAlgorithm)
        
        texture.horizontalWrappingMode = self.horizontalWrappingMode
        texture.verticalWrappingMode = self.verticalWrappingMode
        
        return texture
    }
    
    @inlinable
    public func verticalFlipped() -> Self {
        var copy = self
        copy.setOrientation(.downMirrored)
        return copy
    }
    
    @inlinable
    public func horizontalFlipped() -> Self {
        var copy = self
        copy.setOrientation(.upMirrored)
        return copy
    }
}

extension _TextureProtocolImplement {
    
    @inlinable
    public func pixel(_ point: Point) -> Pixel {
        
        switch resamplingAlgorithm {
        case .none: return read_source(Int(floor(point.x)), Int(floor(point.y)))
        case .linear: return sampling2(point: point, sampler: LinearInterpolate)
        case .cosine: return sampling2(point: point, sampler: CosineInterpolate)
        case .cubic: return sampling4(point: point, sampler: CubicInterpolate)
        case let .hermite(s, e):
            
            let s = Pixel.Scalar(s)
            let e = Pixel.Scalar(e)
            
            @inline(__always)
            func _kernel(_ t: Pixel.Scalar, _ a: Pixel, _ b: Pixel, _ c: Pixel, _ d: Pixel) -> Pixel {
                return HermiteInterpolate(t, a, b, c, d, s, e)
            }
            
            return sampling4(point: point, sampler: _kernel)
            
        case let .mitchell(B, C):
            
            let _a1 = 12 - 9 * B - 6 * C
            let _b1 = -18 + 12 * B + 6 * C
            let _c1 = 6 - 2 * B
            let _a2 = -B - 6 * C
            let _b2 = 6 * B + 30 * C
            let _c2 = -12 * B - 48 * C
            let _d2 = 8 * B + 24 * C
            
            let a1 = Pixel.Scalar(_a1)
            let b1 = Pixel.Scalar(_b1)
            let c1 = Pixel.Scalar(_c1)
            let a2 = Pixel.Scalar(_a2)
            let b2 = Pixel.Scalar(_b2)
            let c2 = Pixel.Scalar(_c2)
            let d2 = Pixel.Scalar(_d2)
            
            @inline(__always)
            func _kernel(_ x: Pixel.Scalar) -> Pixel.Scalar {
                if x < 1 {
                    let u = a1 * x + b1
                    return u * x * x + c1
                }
                if x < 2 {
                    let u = a2 * x + b2
                    let v = u * x + c2
                    return v * x + d2
                }
                return 0
            }
            
            return convolve(point: point, kernel_size: 5, kernel: _kernel)
            
        case .lanczos(0): return read_source(Int(floor(point.x)), Int(floor(point.y)))
        case .lanczos(1):
            
            @inline(__always)
            func _kernel(_ x: Pixel.Scalar) -> Pixel.Scalar {
                if x == 0 {
                    return 1
                }
                if x < 1 {
                    let _x = .pi * x
                    let _sinc = .sin(_x) / _x
                    return _sinc * _sinc
                }
                return 0
            }
            
            return convolve(point: point, kernel_size: 2, kernel: _kernel)
            
        case let .lanczos(a):
            
            let a = Pixel.Scalar(a)
            let _a = 1 / a
            
            @inline(__always)
            func _kernel(_ x: Pixel.Scalar) -> Pixel.Scalar {
                if x == 0 {
                    return 1
                }
                if x < a {
                    let _x = .pi * x
                    let u = .sin(_x) * .sin(_x * _a)
                    let v = _x * _x
                    return a * u / v
                }
                return 0
            }
            
            return convolve(point: point, kernel_size: Int(a) << 1, kernel: _kernel)
        }
    }
}

extension WrappingMode {
    
    @inlinable
    @inline(__always)
    func addressing(_ x: Int, _ upperbound: Int) -> (Bool, Int) {
        switch self {
        case .none: return 0..<upperbound ~= x ? (true, x) : (false, x.clamped(to: 0..<upperbound))
        case .clamp: return (true, x.clamped(to: 0..<upperbound))
        case .repeat:
            let _x = x % upperbound
            return _x < 0 ? (true, _x + upperbound) : (true, _x)
        case .mirror:
            let ax = abs(x)
            let _x = ax % upperbound
            return (ax / upperbound) & 1 == 1 ? (true, upperbound - _x - 1) : (true, _x)
        }
    }
}

extension _TextureProtocolImplement {
    
    @inlinable
    @inline(__always)
    func convolve(point: Point, kernel_size: Int, kernel: (Pixel.Scalar) -> Pixel.Scalar) -> Pixel {
        
        var pixel = Pixel()
        var t: Pixel.Scalar = 0
        
        let _x = Int(floor(point.x))
        let _y = Int(floor(point.y))
        
        let a = kernel_size >> 1
        let b = 1 - kernel_size & 1
        let min_x = _x - a + b
        let max_x = min_x + kernel_size
        let min_y = _y - a + b
        let max_y = min_y + kernel_size
        
        for y in min_y..<max_y {
            for x in min_x..<max_x {
                let k = kernel(Pixel.Scalar(point.distance(to: Point(x: x, y: y))))
                pixel += read_source(x, y) * k
                t += k
            }
        }
        return t == 0 ? Pixel() : pixel / t
    }
    
    @inlinable
    @inline(__always)
    func sampling2(point: Point, sampler: (Pixel.Scalar, Pixel, Pixel) -> Pixel) -> Pixel {
        
        let _i = floor(point.x)
        let _j = floor(point.y)
        let _tx = Pixel.Scalar(point.x - _i)
        let _ty = Pixel.Scalar(point.y - _j)
        
        let _x1 = Int(_i)
        let _y1 = Int(_j)
        let _x2 = _x1 + 1
        let _y2 = _y1 + 1
        
        let _s1 = read_source(_x1, _y1)
        let _s2 = read_source(_x2, _y1)
        let _s3 = read_source(_x1, _y2)
        let _s4 = read_source(_x2, _y2)
        
        return sampler(_ty, sampler(_tx, _s1, _s2), sampler(_tx, _s3, _s4))
    }
    
    @inlinable
    @inline(__always)
    func sampling4(point: Point, sampler: (Pixel.Scalar, Pixel, Pixel, Pixel, Pixel) -> Pixel) -> Pixel {
        
        let _i = floor(point.x)
        let _j = floor(point.y)
        let _tx = Pixel.Scalar(point.x - _i)
        let _ty = Pixel.Scalar(point.y - _j)
        
        let _x2 = Int(_i)
        let _y2 = Int(_j)
        let _x3 = _x2 + 1
        let _y3 = _y2 + 1
        let _x1 = _x2 - 1
        let _y1 = _y2 - 1
        let _x4 = _x2 + 2
        let _y4 = _y2 + 2
        
        let _s1 = read_source(_x1, _y1)
        let _s2 = read_source(_x2, _y1)
        let _s3 = read_source(_x3, _y1)
        let _s4 = read_source(_x4, _y1)
        let _s5 = read_source(_x1, _y2)
        let _s6 = read_source(_x2, _y2)
        let _s7 = read_source(_x3, _y2)
        let _s8 = read_source(_x4, _y2)
        let _s9 = read_source(_x1, _y3)
        let _s10 = read_source(_x2, _y3)
        let _s11 = read_source(_x3, _y3)
        let _s12 = read_source(_x4, _y3)
        let _s13 = read_source(_x1, _y4)
        let _s14 = read_source(_x2, _y4)
        let _s15 = read_source(_x3, _y4)
        let _s16 = read_source(_x4, _y4)
        
        let _u1 = sampler(_tx, _s1, _s2, _s3, _s4)
        let _u2 = sampler(_tx, _s5, _s6, _s7, _s8)
        let _u3 = sampler(_tx, _s9, _s10, _s11, _s12)
        let _u4 = sampler(_tx, _s13, _s14, _s15, _s16)
        
        return sampler(_ty, _u1, _u2, _u3, _u4)
    }
}
