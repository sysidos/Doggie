//
//  QuadBezier.swift
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

public struct QuadBezier<Element : ScalarMultiplicative> : Equatable, BezierProtocol where Element.Scalar == Double {
    
    public typealias Scalar = Double
    
    public var p0: Element
    public var p1: Element
    public var p2: Element
    
    @inlinable
    public init() {
        self.p0 = Element()
        self.p1 = Element()
        self.p2 = Element()
    }
    
    @inlinable
    public init(_ p0: Element, _ p1: Element, _ p2: Element) {
        self.p0 = p0
        self.p1 = p1
        self.p2 = p2
    }
}

extension QuadBezier {
    
    @inlinable
    public init(_ bezier: QuadBezier<Element>) {
        self.init(bezier.p0, bezier.p1, bezier.p2)
    }
}

extension QuadBezier: Decodable where Element : Decodable {
    
    @inlinable
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.init(try container.decode(Element.self),
                  try container.decode(Element.self),
                  try container.decode(Element.self))
    }
}

extension QuadBezier: Encodable where Element : Encodable {
    
    @inlinable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(p0)
        try container.encode(p1)
        try container.encode(p2)
    }
}

extension QuadBezier {
    
    public typealias Indices = Range<Int>
    
    public typealias Index = Int
    
    @inlinable
    public var startIndex: Int {
        return 0
    }
    @inlinable
    public var endIndex: Int {
        return 3
    }
    
    @inlinable
    public subscript(position: Int) -> Element {
        get {
            switch position {
            case 0: return p0
            case 1: return p1
            case 2: return p2
            default: fatalError()
            }
        }
        set {
            switch position {
            case 0: p0 = newValue
            case 1: p1 = newValue
            case 2: p2 = newValue
            default: fatalError()
            }
        }
    }
}

extension QuadBezier {
    
    @inlinable
    public func eval(_ t: Double) -> Element {
        let _t = 1 - t
        let a = _t * _t * p0
        let b = 2 * _t * t * p1
        let c = t * t * p2
        return a + b + c
    }
}

extension QuadBezier where Element == Double {
    
    @inlinable
    public var polynomial: Polynomial {
        let a = p0
        let b = 2 * (p1 - p0)
        let c = p0 + p2 - 2 * p1
        return [a, b, c]
    }
}

extension QuadBezier {
    
    @inlinable
    public func split(_ t: Double) -> (QuadBezier, QuadBezier) {
        let q0 = p0 + t * (p1 - p0)
        let q1 = p1 + t * (p2 - p1)
        let u0 = q0 + t * (q1 - q0)
        return (QuadBezier(p0, q0, u0), QuadBezier(u0, q1, p2))
    }
}

extension QuadBezier {
    
    @inlinable
    public func derivative() -> LineSegment<Element> {
        return LineSegment(2 * (p1 - p0), 2 * (p2 - p1))
    }
}

extension QuadBezier where Element == Point {
    
    @inlinable
    public func closest(_ point: Point) -> [Double] {
        let a = p0 - point
        let b = 2 * (p1 - p0)
        let c = p0 + p2 - 2 * p1
        let x: Polynomial = [a.x, b.x, c.x]
        let y: Polynomial = [a.y, b.y, c.y]
        let dot = x * x + y * y
        return dot.derivative.roots.sorted(by: { dot.eval($0) })
    }
}

extension QuadBezier where Element == Point {
    
    @inlinable
    public var area: Double {
        let a = p0.x - 2 * p1.x + p2.x
        let b = 2 * (p1.x - p0.x)
        
        let c = p0.y - 2 * p1.y + p2.y
        let d = 2 * (p1.y - p0.y)
        
        return 0.5 * (p0.x * p2.y - p2.x * p0.y) + (b * c - a * d) / 6
    }
}

extension QuadBezier where Element == Point {
    
    @inline(__always)
    private func _length(_ t: Double, _ a: Double, _ b: Double, _ c: Double) -> Double {
        
        if a.almostZero() {
            if b.almostZero() {
                return sqrt(c) * t
            }
            let g = pow(b * t + c, 1.5)
            let h = pow(c, 1.5)
            return 2 * (g - h) / (3 * b)
        }
        if b.almostZero() {
            let g = sqrt(a * t * t + c)
            let h = sqrt(a)
            let i = log(h * g + a * t)
            let j = log(h * sqrt(c))
            return 0.5 * (t * g + c * (i - j) / h)
        }
        if a.almostEqual(c) && a.almostEqual(-0.5 * b) {
            let g = t - 1
            if g.almostZero() {
                return 0.5 * sqrt(a)
            }
            let h = sqrt(a * g * g)
            return 0.5 * t * (t - 2) * h / g
        }
        
        let delta = b * b - 4 * a * c
        if delta.almostZero() {
            let g = sqrt(a)
            let h = b > 0 ? sqrt(c) : -sqrt(c)
            let i = g * t + h
            if i.almostZero() {
                return 0.5 * c / g
            }
            let j = 0.5 * t * abs(i) * (i + h) / i
            return t < -b / a ? c / g + j : j
        }
        
        let g = 2 * sqrt(a * (t * (a * t + b) + c))
        let h = 2 * a * t + b
        let i = 0.125 * pow(a, -1.5)
        let j = 2 * sqrt(a * c)
        let k = log(g + h)
        let l = log(j + b)
        return i * (g * h - j * b - delta * (k - l))
    }
    
    public func length(_ t: Double) -> Double {
        
        if t.almostZero() {
            return t
        }
        
        let x = QuadBezier<Double>(p0.x, p1.x, p2.x).polynomial.derivative
        let y = QuadBezier<Double>(p0.y, p1.y, p2.y).polynomial.derivative
        
        let u = x * x + y * y
        
        return _length(t, u[2], u[1], u[0])
    }
    
    public func inverseLength(_ length: Double) -> Double {
        
        if length.almostZero() {
            return length
        }
        
        let x = QuadBezier<Double>(p0.x, p1.x, p2.x).polynomial.derivative
        let y = QuadBezier<Double>(p0.y, p1.y, p2.y).polynomial.derivative
        
        let u = x * x + y * y
        
        let a = u[2]
        let b = u[1]
        let c = u[0]
        
        if a.almostZero() {
            return b.almostZero() ? length / sqrt(c) : (pow(1.5 * b * length, 2 / 3) - c) / b
        }
        if a.almostEqual(c) && a.almostEqual(-0.5 * b) && length.almostEqual(0.5 * sqrt(a)) {
            return 1
        }
        
        var t = length / _length(1, a, b, c)
        
        t -= (_length(t, a, b, c) - length) / sqrt((a * t + b) * t + c)
        t -= (_length(t, a, b, c) - length) / sqrt((a * t + b) * t + c)
        t -= (_length(t, a, b, c) - length) / sqrt((a * t + b) * t + c)
        t -= (_length(t, a, b, c) - length) / sqrt((a * t + b) * t + c)
        
        return t
    }
}

extension QuadBezier where Element == Double {
    
    @inlinable
    public var stationary: OptionOneCollection<Double> {
        let d = p0 + p2 - 2 * p1
        if d.almostZero() {
            return OptionOneCollection(nil)
        }
        return OptionOneCollection((p0 - p1) / d)
    }
}

extension QuadBezier where Element == Point {
    
    @inlinable
    public var boundary: Rect {
        
        let bx = QuadBezier<Double>(p0.x, p1.x, p2.x).stationary.value
        let by = QuadBezier<Double>(p0.y, p1.y, p2.y).stationary.value
        
        let minX = bx.map { Swift.min(p0.x, p2.x, $0) } ?? Swift.min(p0.x, p2.x)
        let minY = by.map { Swift.min(p0.y, p2.y, $0) } ?? Swift.min(p0.y, p2.y)
        let maxX = bx.map { Swift.max(p0.x, p2.x, $0) } ?? Swift.max(p0.x, p2.x)
        let maxY = by.map { Swift.max(p0.y, p2.y, $0) } ?? Swift.max(p0.y, p2.y)
        
        return Rect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

extension QuadBezier where Element == Point {
    
    @inlinable
    public func overlap(_ other: LineSegment<Element>) -> Bool {
        
        let a = p0 - other.p0
        let b = 2 * (p1 - p0)
        let c = p0 - 2 * p1 + p2
        
        let u0: Polynomial = [a.x, b.x, c.x]
        let u1 = other.p0.x - other.p1.x
        
        let v0: Polynomial = [a.y, b.y, c.y]
        let v1 = other.p0.y - other.p1.y
        
        let det = u1 * v0 - u0 * v1
        return det.allSatisfy { $0.almostZero() }
    }
    
    @inlinable
    public func overlap(_ other: QuadBezier) -> Bool {
        
        let a = p0 - other.p0
        let b = 2 * (p1 - p0)
        let c = p0 - 2 * p1 + p2
        
        let u0: Polynomial = [a.x, b.x, c.x]
        let u1 = 2 * (other.p0.x - other.p1.x)
        let u2 = 2 * other.p1.x - other.p0.x -  other.p2.x
        
        let v0: Polynomial = [a.y, b.y, c.y]
        let v1 = 2 * (other.p0.y - other.p1.y)
        let v2 = 2 * other.p1.y - other.p0.y -  other.p2.y
        
        // Bézout matrix
        let m00 = u2 * v1 - u1 * v2
        let m01 = u2 * v0 - u0 * v2
        let m10 = m01
        let m11 = u1 * v0 - u0 * v1
        
        let det = m00 * m11 - m01 * m10
        return det.allSatisfy { $0.almostZero() }
    }
    
    @inlinable
    public func intersect(_ other: LineSegment<Element>) -> [Double]? {
        
        let a = p0 - other.p0
        let b = 2 * (p1 - p0)
        let c = p0 - 2 * p1 + p2
        
        let u0: Polynomial = [a.x, b.x, c.x]
        let u1 = other.p0.x - other.p1.x
        
        let v0: Polynomial = [a.y, b.y, c.y]
        let v1 = other.p0.y - other.p1.y
        
        let det = u1 * v0 - u0 * v1
        return det.allSatisfy { $0.almostZero() } ? nil : det.roots
    }
    
    @inlinable
    public func intersect(_ other: QuadBezier) -> [Double]? {
        
        let a = p0 - other.p0
        let b = 2 * (p1 - p0)
        let c = p0 - 2 * p1 + p2
        
        let u0: Polynomial = [a.x, b.x, c.x]
        let u1 = 2 * (other.p0.x - other.p1.x)
        let u2 = 2 * other.p1.x - other.p0.x -  other.p2.x
        
        let v0: Polynomial = [a.y, b.y, c.y]
        let v1 = 2 * (other.p0.y - other.p1.y)
        let v2 = 2 * other.p1.y - other.p0.y -  other.p2.y
        
        // Bézout matrix
        let m00 = u2 * v1 - u1 * v2
        let m01 = u2 * v0 - u0 * v2
        let m10 = m01
        let m11 = u1 * v0 - u0 * v1
        
        let det = m00 * m11 - m01 * m10
        return det.allSatisfy { $0.almostZero() } ? nil : det.roots
    }
}

@inlinable
public prefix func + <Element>(x: QuadBezier<Element>) -> QuadBezier<Element> {
    return x
}
@inlinable
public prefix func - <Element>(x: QuadBezier<Element>) -> QuadBezier<Element> {
    return QuadBezier(-x.p0, -x.p1, -x.p2)
}
@inlinable
public func + <Element>(lhs: QuadBezier<Element>, rhs: QuadBezier<Element>) -> QuadBezier<Element> {
    return QuadBezier(lhs.p0 + rhs.p0, lhs.p1 + rhs.p1, lhs.p2 + rhs.p2)
}
@inlinable
public func - <Element>(lhs: QuadBezier<Element>, rhs: QuadBezier<Element>) -> QuadBezier<Element> {
    return QuadBezier(lhs.p0 - rhs.p0, lhs.p1 - rhs.p1, lhs.p2 - rhs.p2)
}
@inlinable
public func * <Element>(lhs: Double, rhs: QuadBezier<Element>) -> QuadBezier<Element> {
    return QuadBezier(lhs * rhs.p0, lhs * rhs.p1, lhs * rhs.p2)
}
@inlinable
public func * <Element>(lhs: QuadBezier<Element>, rhs: Double) -> QuadBezier<Element> {
    return QuadBezier(lhs.p0 * rhs, lhs.p1 * rhs, lhs.p2 * rhs)
}
@inlinable
public func / <Element>(lhs: QuadBezier<Element>, rhs: Double) -> QuadBezier<Element> {
    return QuadBezier(lhs.p0 / rhs, lhs.p1 / rhs, lhs.p2 / rhs)
}
@inlinable
public func += <Element>(lhs: inout QuadBezier<Element>, rhs: QuadBezier<Element>) {
    lhs = lhs + rhs
}
@inlinable
public func -= <Element>(lhs: inout QuadBezier<Element>, rhs: QuadBezier<Element>) {
    lhs = lhs - rhs
}
@inlinable
public func *= <Element>(lhs: inout QuadBezier<Element>, rhs: Double) {
    lhs = lhs * rhs
}
@inlinable
public func /= <Element>(lhs: inout QuadBezier<Element>, rhs: Double) {
    lhs = lhs / rhs
}

@inlinable
public func * (lhs: QuadBezier<Point>, rhs: SDTransform) -> QuadBezier<Point> {
    return QuadBezier(lhs.p0 * rhs, lhs.p1 * rhs, lhs.p2 * rhs)
}
@inlinable
public func *= (lhs: inout QuadBezier<Point>, rhs: SDTransform) {
    lhs = lhs * rhs
}
@inlinable
public func * (lhs: QuadBezier<Vector>, rhs: Matrix) -> QuadBezier<Vector> {
    return QuadBezier(lhs.p0 * rhs, lhs.p1 * rhs, lhs.p2 * rhs)
}
@inlinable
public func *= (lhs: inout QuadBezier<Vector>, rhs: Matrix) {
    lhs = lhs * rhs
}