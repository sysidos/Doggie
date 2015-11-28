//
//  Geometry.swift
//
//  The MIT License
//  Copyright (c) 2015 Susan Cheng. All rights reserved.
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

public struct Radius {
    
    public var x: Double
    public var y: Double
    
    public init() {
        self.x = 0
        self.y = 0
    }
    
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
    public init(x: Int, y: Int) {
        self.x = Double(x)
        self.y = Double(y)
    }
}

extension Radius: CustomStringConvertible, CustomDebugStringConvertible {
    public var description: String {
        return "{x: \(x), y: \(y)}"
    }
    public var debugDescription: String {
        return "{x: \(x), y: \(y)}"
    }
}

extension Radius: Hashable {
    
    public var hashValue: Int {
        return hash(x, y)
    }
}

public func == (lhs: Radius, rhs: Radius) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
}

public func Ellipse(t: Double, _ p: Point, _ r: Radius) -> Point {
    return Point(x: r.x * cos(t) + p.x, y: r.y * sin(t) + p.y)
}

public func EllipseRadius(p0: Point, _ p1: Point, _ r: Radius, _ rotate: Double) -> Radius {
    let _p = p1 - p0
    let _tx = _p.x * cos(rotate) + _p.y * sin(rotate)
    let _ty = _p.y * cos(rotate) - _p.x * sin(rotate)
    let _atan = atan2(_ty / r.y, _tx / r.x)
    return Radius(x: _tx / (2 * cos(_atan)), y: _ty / (2 * sin(_atan)))
}

public func EllipseCenter(r: Radius, _ rotate: Double, _ a: Point, _ b: Point) -> [Point] {
    
    let _sin = sin(rotate)
    let _cos = cos(rotate)
    
    let ax = a.x * _cos + a.y * _sin / r.x
    let ay = a.y * _cos - a.x * _sin / r.y
    let bx = b.x * _cos + b.y * _sin / r.x
    let by = b.y * _cos - b.x * _sin / r.y
    
    let dx = ax - bx
    let dy = ay - by
    let d = dx * dx + dy * dy
    
    if d == 4 {
        let _x = (ax + bx) * r.x * 0.5
        let _y = (ay + by) * r.y * 0.5
        return [Point(x: _x * _cos - _y * _sin, y: _x * _sin + _y * _cos)]
    } else if d < 4 {
        let _x = (ax + bx) * r.x * 0.5
        let _y = (ay + by) * r.y * 0.5
        let _t = sqrt((1 - d * 0.25) / d)
        
        let cx1 = _x + _t * (ay - by) * r.x
        let cy1 = _y + _t * (bx - ax) * r.y
        let cx2 = _x - _t * (ay - by) * r.x
        let cy2 = _y - _t * (bx - ax) * r.y
        
        return [Point(x: cx1 * _cos - cy1 * _sin, y: cx1 * _sin + cy1 * _cos),
            Point(x: cx2 * _cos - cy2 * _sin, y: cx2 * _sin + cy2 * _cos)]
    }
    
    return []
}

///
/// :param: rx radius of ellipse in x-axis
/// :param: ry radius of ellipse in y-axis
///
/// :param: a value of 'a' in matrix if parallel to x-axis or value of 'd' in matrix if parallel to y-axis.
/// :param: b value of 'b' in matrix if parallel to x-axis or value of 'e' in matrix if parallel to y-axis.
///
/// Transformation Matrix:
///
///     ⎛ a b c ⎞ ⎛ A cos(t) ⎞
///     ⎜ d e f ⎟ ⎜ B sin(t) ⎟
///     ⎝ 0 0 1 ⎠ ⎝    1     ⎠
///
public func EllipseStationary(r: Radius, _ a: Double, _ b: Double) -> Double {
    return atan2(r.y * b, r.x * a)
}

///
/// Transformation Matrix:
///
///     ⎛ a b c ⎞ ⎛ A cos(t) ⎞
///     ⎜ d e f ⎟ ⎜ B sin(t) ⎟
///     ⎝ 0 0 1 ⎠ ⎝    1     ⎠
///
public func EllipseBound<T: SDTransformType>(center: Point, _ r: Radius, _ matrix: T) -> Rect {
    
    let t1 = EllipseStationary(r, matrix.a, matrix.b)
    let t2 = EllipseStationary(r, matrix.d, matrix.e)
    
    let p0 = Ellipse(t1, center, r)
    let p1 = Ellipse(t1 + M_PI, center, r)
    let p2 = Ellipse(t2, center, r)
    let p3 = Ellipse(t2 + M_PI, center, r)
    
    let _p0 = matrix.a * p0.x + matrix.b * p0.y
    let _p1 = matrix.a * p1.x + matrix.b * p1.y
    let _p2 = matrix.d * p2.x + matrix.e * p2.y
    let _p3 = matrix.d * p3.x + matrix.e * p3.y
    
    let minX = min(_p0, _p1)
    let minY = min(_p2, _p3)
    let maxX = max(_p0, _p1)
    let maxY = max(_p2, _p3)
    
    return Rect(x: minX + matrix.c, y: minY + matrix.f, width: maxX - minX, height: maxY - minY)
}

public func Bezier(t: Double, _ p: Double ... ) -> Double {
    return Bezier(t, p)
}

public func Bezier(t: Double, _ p: Point ... ) -> Point {
    return Bezier(t, p)
}

public func Bezier(t: Double, _ p: Vector2D ... ) -> Vector2D {
    return Bezier(t, p)
}

public func Bezier(t: Double, _ p: Vector3D ... ) -> Vector3D {
    return Bezier(t, p)
}

public func SplitBezier(t: Double, _ p: Double ... ) -> ([Double], [Double]) {
    return SplitBezier(t, p)
}

public func SplitBezier(t: Double, _ p: Point ... ) -> ([Point], [Point]) {
    return SplitBezier(t, p)
}

public func SplitBezier(t: Double, _ p: Vector2D ... ) -> ([Vector2D], [Vector2D]) {
    return SplitBezier(t, p)
}

public func SplitBezier(t: Double, _ p: Vector3D ... ) -> ([Vector3D], [Vector3D]) {
    return SplitBezier(t, p)
}

public func BezierDerivative(t: Double, _ p: Double ... ) -> Double {
    return Bezier(t, BezierDerivative(p))
}

public func BezierDerivative(t: Double, _ p: Point ... ) -> Point {
    return Bezier(t, BezierDerivative(p))
}

public func BezierDerivative(t: Double, _ p: Vector2D ... ) -> Vector2D {
    return Bezier(t, BezierDerivative(p))
}

public func BezierDerivative(t: Double, _ p: Vector3D ... ) -> Vector3D {
    return Bezier(t, BezierDerivative(p))
}

public func BezierDerivative(p: Double ... ) -> [Double] {
    return BezierDerivative(p)
}

public func BezierDerivative(p: Point ... ) -> [Point] {
    return BezierDerivative(p)
}

public func BezierDerivative(p: Vector2D ... ) -> [Vector2D] {
    return BezierDerivative(p)
}

public func BezierDerivative(p: Vector3D ... ) -> [Vector3D] {
    return BezierDerivative(p)
}

private func Bezier(t: Double, _ p: [Double]) -> Double {
    var result: Double = 0
    let _n = p.count - 1
    for idx in 0..._n {
        let b = Double(combination(UInt(_n), UInt(idx))) * pow(t, Double(idx)) * pow(1 - t, Double(_n - idx))
        result += b * p[idx]
    }
    return result
}

private func Bezier(t: Double, _ p: [Point]) -> Point {
    var result = Point(x: 0, y: 0)
    let _n = p.count - 1
    for idx in 0..._n {
        let b = Double(combination(UInt(_n), UInt(idx))) * pow(t, Double(idx)) * pow(1 - t, Double(_n - idx))
        result.x += b * p[idx].x
        result.y += b * p[idx].y
    }
    return result
}

private func Bezier(t: Double, _ p: [Vector2D]) -> Vector2D {
    var result = Vector2D(x: 0, y: 0)
    let _n = p.count - 1
    for idx in 0..._n {
        let b = Double(combination(UInt(_n), UInt(idx))) * pow(t, Double(idx)) * pow(1 - t, Double(_n - idx))
        result += b * p[idx]
    }
    return result
}

private func Bezier(t: Double, _ p: [Vector3D]) -> Vector3D {
    var result = Vector3D(x: 0, y: 0, z: 0)
    let _n = p.count - 1
    for idx in 0..._n {
        let b = Double(combination(UInt(_n), UInt(idx))) * pow(t, Double(idx)) * pow(1 - t, Double(_n - idx))
        result += b * p[idx]
    }
    return result
}

public func ClosestBezier(point: Point, _ b0: Point, _ b1: Point, _ b2: Point) -> Double {
    
    let x: Polynomial = [b0.x - point.x, 2 * (b1.x - b0.x), b0.x - 2 * b1.x + b2.x]
    let y: Polynomial = [b0.y - point.y, 2 * (b1.y - b0.y), b0.y - 2 * b1.y + b2.y]
    
    let dot = x * x + y * y
    let _dot = dot.derivative
    
    return _dot.roots.minElement { dot.eval($0) }!
}

public func ClosestBezier(point: Point, _ b0: Point, _ b1: Point, _ b2: Point, _ b3: Point) -> Double {
    
    let x: Polynomial = [b0.x - point.x, 3 * (b1.x - b0.x), 3 * (b2.x + b0.x) - 6 * b1.x, b3.x + 3 * (b1.x - b2.x) - b0.x]
    let y: Polynomial = [b0.y - point.y, 3 * (b1.y - b0.y), 3 * (b2.y + b0.y) - 6 * b1.y, b3.y + 3 * (b1.y - b2.y) - b0.y]
    
    let dot = x * x + y * y
    let _dot = dot.derivative
    
    return _dot.roots.minElement { dot.eval($0) }!
}

private func SplitBezier(t: Double, _ p: [Double]) -> ([Double], [Double]) {
    let _t = 1 - t
    if p.count == 2 {
        let split = _t * p.first! + t * p.last!
        return ([p.first!, split], [split, p.last!])
    }
    var subpath = [Double]()
    var lastPoint = p.first!
    for current in p.dropFirst() {
        subpath.append(_t * lastPoint + t * current)
        lastPoint = current
    }
    let split = SplitBezier(t, subpath)
    return ([p.first!] + split.0, split.1 + [p.last!])
}

private func SplitBezier(t: Double, _ p: [Point]) -> ([Point], [Point]) {
    let _t = 1 - t
    if p.count == 2 {
        let sx = _t * p.first!.x + t * p.last!.x
        let sy = _t * p.first!.y + t * p.last!.y
        return ([p.first!, Point(x: sx, y: sy)], [Point(x: sx, y: sy), p.last!])
    }
    var subpath = [Point]()
    var lastPoint = p.first!
    for current in p.dropFirst() {
        let sx = _t * lastPoint.x + t * current.x
        let sy = _t * lastPoint.y + t * current.y
        subpath.append(Point(x: sx, y: sy))
        lastPoint = current
    }
    let split = SplitBezier(t, subpath)
    return ([p.first!] + split.0, split.1 + [p.last!])
}

private func SplitBezier(t: Double, _ p: [Vector2D]) -> ([Vector2D], [Vector2D]) {
    let _t = 1 - t
    if p.count == 2 {
        let split = _t * p.first! + t * p.last!
        return ([p.first!, split], [split, p.last!])
    }
    var subpath = [Vector2D]()
    var lastPoint = p.first!
    for current in p.dropFirst() {
        subpath.append(_t * lastPoint + t * current)
        lastPoint = current
    }
    let split = SplitBezier(t, subpath)
    return ([p.first!] + split.0, split.1 + [p.last!])
}

private func SplitBezier(t: Double, _ p: [Vector3D]) -> ([Vector3D], [Vector3D]) {
    let _t = 1 - t
    if p.count == 2 {
        let split = _t * p.first! + t * p.last!
        return ([p.first!, split], [split, p.last!])
    }
    var subpath = [Vector3D]()
    var lastPoint = p.first!
    for current in p.dropFirst() {
        subpath.append(_t * lastPoint + t * current)
        lastPoint = current
    }
    let split = SplitBezier(t, subpath)
    return ([p.first!] + split.0, split.1 + [p.last!])
}

private func BezierDerivative(p: [Double]) -> [Double] {
    let n = Double(p.count)
    var de = [Double]()
    var lastPoint = p.first!
    for current in p.dropFirst() {
        de.append(n * (current - lastPoint))
        lastPoint = current
    }
    return de
}

private func BezierDerivative(p: [Point]) -> [Point] {
    let n = Double(p.count)
    var de = [Point]()
    var lastPoint = p.first!
    for current in p.dropFirst() {
        let px = n * (current.x - lastPoint.x)
        let py = n * (current.y - lastPoint.y)
        de.append(Point(x: px, y: py))
        lastPoint = current
    }
    return de
}

private func BezierDerivative(p: [Vector2D]) -> [Vector2D] {
    let n = Double(p.count)
    var de = [Vector2D]()
    var lastPoint = p.first!
    for current in p.dropFirst() {
        de.append(n * (current - lastPoint))
        lastPoint = current
    }
    return de
}

private func BezierDerivative(p: [Vector3D]) -> [Vector3D] {
    let n = Double(p.count)
    var de = [Vector3D]()
    var lastPoint = p.first!
    for current in p.dropFirst() {
        de.append(n * (current - lastPoint))
        lastPoint = current
    }
    return de
}

public func QuadBezierStationary(p0: Double, _ p1: Double, _ p2: Double) -> Double? {
    let d = p0 + p2 - 2 * p1
    if d.almostZero {
        return nil
    }
    return ((p0 - p1) / d).clamp(0...1)
}

///
/// :param: a value of 'a' in matrix if parallel to x-axis or value of 'd' in matrix if parallel to y-axis.
/// :param: b value of 'b' in matrix if parallel to x-axis or value of 'e' in matrix if parallel to y-axis.
///
/// Transformation Matrix:
///
///     ⎛ a b c ⎞ ⎛ B_x(t) ⎞
///     ⎜ d e f ⎟ ⎜ B_y(t) ⎟
///     ⎝ 0 0 1 ⎠ ⎝   1    ⎠
///
public func QuadBezierStationary(p0: Point, _ p1: Point, _ p2: Point, _ a: Double, _ b: Double) -> Double? {
    let d = a * (p0.x + p2.x - 2 * p1.x) + b * (p0.y + p2.y - 2 * p1.y)
    if d.almostZero {
        return nil
    }
    return ((a * (p0.x - p1.x) + b * (p0.y - p1.y)) / d).clamp(0...1)
}

public func CubicBezierStationary(p0: Double, _ p1: Double, _ p2: Double, _ p3: Double) -> [Double] {
    let _a = 3 * (p3 - p0) + 9 * (p1 - p2)
    let _b = 6 * (p2 + p0) - 12 * p1
    let _c = 3 * (p1 - p0)
    if _a.almostZero {
        if _b.almostZero {
            return []
        }
        let t = -_c / _b
        if (0.0...1.0).contains(t) {
            return [t]
        }
    } else {
        let delta = _b * _b - 4 * _a * _c
        let _a2 = 2 * _a
        let _b2 = -_b / _a2
        if !delta.isSignMinus {
            let sqrt_delta = sqrt(delta) / _a2
            let t1 = _b2 + sqrt_delta
            let t2 = _b2 - sqrt_delta
            if (0.0...1.0).contains(t1) {
                if (0.0...1.0).contains(t2) {
                    return [t1, t2]
                } else {
                    return [t1]
                }
            } else if (0.0...1.0).contains(t2) {
                return [t2]
            }
        } else if delta.almostZero && (0.0...1.0).contains(_b2) {
            return [_b2]
        }
    }
    return []
}

///
/// :param: a value of 'a' in matrix if parallel to x-axis or value of 'd' in matrix if parallel to y-axis.
/// :param: b value of 'b' in matrix if parallel to x-axis or value of 'e' in matrix if parallel to y-axis.
///
/// Transformation Matrix:
///
///     ⎛ a b c ⎞ ⎛ B_x(t) ⎞
///     ⎜ d e f ⎟ ⎜ B_y(t) ⎟
///     ⎝ 0 0 1 ⎠ ⎝   1    ⎠
///
public func CubicBezierStationary(p0: Point, _ p1: Point, _ p2: Point, _ p3: Point, _ a: Double, _ b: Double) -> [Double] {
    let _ax = 3 * (p3.x - p0.x) + 9 * (p1.x - p2.x)
    let _bx = 6 * (p2.x + p0.x) - 12 * p1.x
    let _cx = 3 * (p1.x - p0.x)
    let _ay = 3 * (p3.y - p0.y) + 9 * (p1.y - p2.y)
    let _by = 6 * (p2.y + p0.y) - 12 * p1.y
    let _cy = 3 * (p1.y - p0.y)
    let _a = a * _ax + b * _ay
    let _b = a * _bx + b * _by
    let _c = a * _cx + b * _cy
    if _a.almostZero {
        if _b.almostZero {
            return []
        }
        let t = -_c / _b
        if (0.0...1.0).contains(t) {
            return [t]
        }
    } else {
        let delta = _b * _b - 4 * _a * _c
        let _a2 = 2 * _a
        let _b2 = -_b / _a2
        if !delta.isSignMinus {
            let sqrt_delta = sqrt(delta) / _a2
            let t1 = _b2 + sqrt_delta
            let t2 = _b2 - sqrt_delta
            if (0.0...1.0).contains(t1) {
                if (0.0...1.0).contains(t2) {
                    return [t1, t2]
                } else {
                    return [t1]
                }
            } else if (0.0...1.0).contains(t2) {
                return [t2]
            }
        } else if delta.almostZero && (0.0...1.0).contains(_b2) {
            return [_b2]
        }
    }
    return []
}

public func QuadBezierBound(p0: Point, _ p1: Point, _ p2: Point) -> Rect {
    
    let tx = [0.0, QuadBezierStationary(p0.x, p1.x, p2.x) ?? 0.0, 1.0]
    let ty = [0.0, QuadBezierStationary(p0.y, p1.y, p2.y) ?? 0.0, 1.0]
    
    let _x = tx.map { Bezier($0, p0.x, p1.x, p2.x) }
    let _y = ty.map { Bezier($0, p0.y, p1.y, p2.y) }
    
    let minX = _x.minElement()!
    let minY = _y.minElement()!
    let maxX = _x.maxElement()!
    let maxY = _y.maxElement()!
    
    return Rect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
}

///
/// Transformation Matrix:
///
///     ⎛ a b c ⎞ ⎛ B_x(t) ⎞
///     ⎜ d e f ⎟ ⎜ B_y(t) ⎟
///     ⎝ 0 0 1 ⎠ ⎝   1    ⎠
///
public func QuadBezierBound<T: SDTransformType>(p0: Point, _ p1: Point, _ p2: Point, _ matrix: T) -> Rect {
    
    let tx = [0.0, QuadBezierStationary(p0, p1, p2, matrix.a, matrix.b) ?? 0.0, 1.0]
    let ty = [0.0, QuadBezierStationary(p0, p1, p2, matrix.d, matrix.e) ?? 0.0, 1.0]
    
    let _x = tx.map { t -> Double in
        let _p = Bezier(t, p0, p1, p2)
        return matrix.a * _p.x + matrix.b * _p.y
    }
    let _y = ty.map { t -> Double in
        let _p = Bezier(t, p0, p1, p2)
        return matrix.d * _p.x + matrix.e * _p.y
    }
    
    let minX = _x.minElement()!
    let minY = _y.minElement()!
    let maxX = _x.maxElement()!
    let maxY = _y.maxElement()!
    
    return Rect(x: minX + matrix.c, y: minY + matrix.f, width: maxX - minX, height: maxY - minY)
}

public func CubicBezierBound(p0: Point, _ p1: Point, _ p2: Point, _ p3: Point) -> Rect {
    
    let tx = [0.0, 1.0] + CubicBezierStationary(p0.x, p1.x, p2.x, p3.x)
    let ty = [0.0, 1.0] + CubicBezierStationary(p0.y, p1.y, p2.y, p3.y)
    
    let _x = tx.map { Bezier($0, p0.x, p1.x, p2.x, p3.x) }
    let _y = ty.map { Bezier($0, p0.y, p1.y, p2.y, p3.y) }
    
    let minX = _x.minElement()!
    let minY = _y.minElement()!
    let maxX = _x.maxElement()!
    let maxY = _y.maxElement()!
    
    return Rect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
}

///
/// Transformation Matrix:
///
///     ⎛ a b c ⎞ ⎛ B_x(t) ⎞
///     ⎜ d e f ⎟ ⎜ B_y(t) ⎟
///     ⎝ 0 0 1 ⎠ ⎝   1    ⎠
///
public func CubicBezierBound<T: SDTransformType>(p0: Point, _ p1: Point, _ p2: Point, _ p3: Point, _ matrix: T) -> Rect {
    
    let tx = [0.0, 1.0] + CubicBezierStationary(p0, p1, p2, p3, matrix.a, matrix.b)
    let ty = [0.0, 1.0] + CubicBezierStationary(p0, p1, p2, p3, matrix.d, matrix.e)
    
    let _x = tx.map { t -> Double in
        let _p = Bezier(t, p0, p1, p2, p3)
        return matrix.a * _p.x + matrix.b * _p.y
    }
    let _y = ty.map { t -> Double in
        let _p = Bezier(t, p0, p1, p2, p3)
        return matrix.d * _p.x + matrix.e * _p.y
    }
    
    let minX = _x.minElement()!
    let minY = _y.minElement()!
    let maxX = _x.maxElement()!
    let maxY = _y.maxElement()!
    
    return Rect(x: minX + matrix.c, y: minY + matrix.f, width: maxX - minX, height: maxY - minY)
}

public func BezierArc(angle: Double) -> [Point] {
    
    let c = 0.551915024494
    
    var counter = 0
    var _angle = abs(angle)
    var result = [Point(x: 1, y: 0)]
    
    while _angle > 0 {
        switch counter & 3 {
        case 0:
            result.append(Point(x: 1, y: c))
            result.append(Point(x: c, y: 1))
            result.append(Point(x: 0, y: 1))
        case 1:
            result.append(Point(x: -c, y: 1))
            result.append(Point(x: -1, y: c))
            result.append(Point(x: -1, y: 0))
        case 2:
            result.append(Point(x: -1, y: -c))
            result.append(Point(x: -c, y: -1))
            result.append(Point(x: 0, y: -1))
        case 3:
            result.append(Point(x: c, y: -1))
            result.append(Point(x: 1, y: -c))
            result.append(Point(x: 1, y: 0))
        default: break
        }
        if _angle < M_PI_2 {
            let offset = Double(counter & 3) * M_PI_2
            let s = _angle + offset
            let _a = result.count - 4
            let _b = result.count - 3
            let _c = result.count - 2
            let _d = result.count - 1
            let end = Point(x: cos(s), y: sin(s))
            let t = ClosestBezier(end, result[_a], result[_b], result[_c], result[_d])
            let split = SplitBezier(t, result[_a], result[_b], result[_c], result[_d]).0
            result[_b] = split[1]
            result[_c] = split[2]
            result[_d] = end
        }
        _angle -= M_PI_2
        ++counter
    }
    return angle.isSignMinus ? result.map { Point(x: $0.x, y: -$0.y) } : result
}

public func CubicBezierSelfIntersect(p0: Point, _ p1: Point, _ p2: Point, _ p3: Point) -> (Double, Double)? {
    
    let a = p3.x - p0.x + 3 * (p1.x - p2.x)
    if a.almostZero {
        return nil
    }
    
    let b = (3 * (p0.x + p2.x) - 6 * p1.x) / a
    let c = (3 * (p1.x - p0.x)) / a
    
    let d = p3.y - p0.y + 3 * (p1.y - p2.y)
    if d.almostZero {
        return nil
    }
    let e = (3 * (p0.y + p2.y) - 6 * p1.y) / d
    if b == e {
        return nil
    }
    let f = (3 * (p1.y - p0.y)) / d
    let g = (f - c) / (b - e)
    
    let g_2 = g * g
    
    let _b = -3 * g
    let _c = 3 * g_2 + 2 * (g * b + c)
    let _d = -g_2 * g - b * g_2 - c * g
    let roots = Polynomial(_d, _c, _b, 2).roots
    if roots.count == 3 {
        return (roots.minElement()!, roots.maxElement()!)
    }
    
    return nil
}

public func LinesIntersect(p0: Point, _ p1: Point, _ p2: Point, _ p3: Point) -> Point? {
    
    let d = (p0.x - p1.x) * (p2.y - p3.y) - (p0.y - p1.y) * (p2.x - p3.x)
    if d.almostZero {
        return nil
    }
    let a = (p0.x * p1.y - p0.y * p1.x) / d
    let b = (p2.x * p3.y - p2.y * p3.x) / d
    return Point(x: (p2.x - p3.x) * a - (p0.x - p1.x) * b, y: (p2.y - p3.y) * a - (p0.y - p1.y) * b)
}

public func EllipseLineIntersect<T: SDTransformType>(center: Point, _ radius: Radius, _ matrix: T, _ p0: Point, _ p1: Point) -> [Point] {
    
    let transform = matrix * SDTransform.Scale(x: radius.x, y: radius.y)
    let inverse = transform.inverse
    let _center = inverse * center
    let _p0 = inverse * p0
    let _p1 = inverse * p1
    let m = (_p1.y - _p0.y) / (_p1.x - _p0.x)
    let n = _p0.y - m * _p0.x
    let a = m * m + 1
    let b = 2 * (m * n - m * _center.y - _center.x)
    let c = _center.y * _center.y - 1 + _center.x * _center.x - 2 * n * _center.y + n * n
    let delta = b * b - 4 * a * c
    if delta > 0 {
        let a_2 = 2 * a
        let x1 = (sqrt(delta) - b) / a_2
        let y1 = m * x1 + n
        let x2 = (-sqrt(delta) - b) / a_2
        let y2 = m * x2 + n
        return [transform * Point(x: x1, y: y1), transform * Point(x: x2, y: y2)]
    } else if delta.almostZero {
        let a_2 = 2 * a
        let x = -b / a_2
        let y = m * x + n
        return [transform * Point(x: x, y: y)]
    }
    return []
}

public func EllipsesIntersect<T1: SDTransformType, T2: SDTransformType>(c1: Point, _ r1: Radius, _ m1: T1, _ c2: Point, _ r2: Radius, _ m2: T2) -> [Point] {
    
    let _m1 = m1 * SDTransform.Translate(x: c1.x, y: c1.y) * SDTransform.Scale(x: r1.x, y: r1.y)
    let _m2 = m2 * SDTransform.Translate(x: c2.x, y: c2.y) * SDTransform.Scale(x: r2.x, y: r2.y)
    let inverse = _m2.inverse * _m1
    
    let a = inverse.a
    let b = inverse.b
    let c = inverse.c
    let d = inverse.d
    let e = inverse.e
    let f = inverse.f
    
    let A = a * a + d * d
    let B = 2 * a * b + 2 * d * e
    let C = b * b + e * e
    let D = 2 * a * c + 2 * d * f
    let E = 2 * b * c + 2 * e * f
    let F = c * c + f * f - 1
    
    let _a = A - D + F
    let _b = 2 * (E - B)
    let _c = 4 * C - 2 * (A - F)
    let _d = 2 * (B + E)
    let _e = A + D + F
    
    return Polynomial(_e, _d, _c, _b, _a).roots.map { t in
        let t2 = t * t
        return _m1 * Point(x: (1 - t2) / (t2 + 1), y: 2 * t / (t2 + 1))
    }
}

public func QuadBezierLineIntersect(b0: Point, _ b1: Point, _ b2: Point, _ l0: Point, _ l1: Point) -> [Double] {
    
    let m = (l1.y - l0.y) / (l1.x - l0.x)
    
    let x2 = b0.x - 2 * b1.x + b2.x
    let x1 = 2 * (b1.x - b0.x)
    let x0 = b0.x - l0.x
    
    let y2 = b0.y - 2 * b1.y + b2.y
    let y1 = 2 * (b1.y - b0.y)
    let y0 = b0.y - l0.y
    
    let _a = y2 - m * x2
    let _b = y1 - m * x1
    let _c = y0 - m * x0
    
    return Polynomial(_c, _b, _a).roots
}

public func CubicBezierLineIntersect(b0: Point, _ b1: Point, _ b2: Point, _ b3: Point, _ l0: Point, _ l1: Point) -> [Double] {
    
    let m = (l1.y - l0.y) / (l1.x - l0.x)
    
    let x3 = b3.x - b0.x + 3 * (b1.x - b2.x)
    let x2 = 3 * (b2.x + b0.x) - 6 * b1.x
    let x1 = 3 * (b1.x - b0.x)
    let x0 = b0.x - l0.x
    
    let y3 = b3.y - b0.y + 3 * (b1.y - b2.y)
    let y2 = 3 * (b2.y + b0.y) - 6 * b1.y
    let y1 = 3 * (b1.y - b0.y)
    let y0 = b0.y - l0.y
    
    let _a = y3 - m * x3
    let _b = y2 - m * x2
    let _c = y1 - m * x1
    let _d = y0 - m * x0
    
    return Polynomial(_d, _c, _b, _a).roots
}

public func QuadBezierEllipseIntersect<T: SDTransformType>(b0: Point, _ b1: Point, _ b2: Point, _ center: Point, _ radius: Radius, _ matrix: T) -> [Double] {
    
    let _m = matrix * SDTransform.Translate(x: center.x, y: center.y) * SDTransform.Scale(x: radius.x, y: radius.y)
    
    let inverse = _m.inverse
    let _b0 = inverse * b0
    let _b1 = inverse * b1
    let _b2 = inverse * b2
    
    let x2 = _b0.x - 2 * _b1.x + _b2.x
    let x1 = 2 * (_b1.x - _b0.x)
    let x0 = _b0.x
    
    let y2 = _b0.y - 2 * _b1.y + _b2.y
    let y1 = 2 * (_b1.y - _b0.y)
    let y0 = _b0.y
    
    let a = x2 * x2 + y2 * y2
    let b = 2 * (x2 * x1 + y2 * y1)
    let c = x1 * x1 + y1 * y1 + 2 * (x2 * x0 + y2 * y0)
    let d = 2 * (x1 * x0 + y1 * y0)
    let e = x0 * x0 + y0 * y0 - 1
    
    return Polynomial(e, d, c, b, a).roots
}

public func QuadBeziersIntersect(b0: Point, _ b1: Point, _ b2: Point, _ b3: Point, _ b4: Point, _ b5: Point) -> [Double] {
    
    let u0: Polynomial = [
        b0.x - b3.x,
        2 * (b1.x - b0.x),
        b0.x - 2 * b1.x + b2.x
    ]
    let u1 = 2 * (b3.x - b4.x)
    let u2 = 2 * b4.x - b3.x -  b5.x
    
    let v0: Polynomial = [
        b0.y - b3.y,
        2 * (b1.y - b0.y),
        b0.y - 2 * b1.y + b2.y
    ]
    let v1 = 2 * (b3.y - b4.y)
    let v2 = 2 * b4.y - b3.y -  b5.y
    
    // Bézout matrix
    let m00 = u2 * v1 - u1 * v2
    let m01 = u2 * v0 - u0 * v2
    let m10 = m01
    let m11 = u1 * v0 - u0 * v1
    
    let det = m00 * m11 - m01 * m10
    
    return det.roots
}

public func CubicBezierEllipseIntersect<T: SDTransformType>(b0: Point, _ b1: Point, _ b2: Point, _ b3: Point, _ center: Point, _ radius: Radius, _ matrix: T) -> [Double] {
    
    let _m = matrix * SDTransform.Translate(x: center.x, y: center.y) * SDTransform.Scale(x: radius.x, y: radius.y)
    
    let inverse = _m.inverse
    let _b0 = inverse * b0
    let _b1 = inverse * b1
    let _b2 = inverse * b2
    let _b3 = inverse * b3
    
    let x3 = _b3.x - _b0.x + 3 * (_b1.x - _b2.x)
    let x2 = 3 * (_b2.x + _b0.x) - 6 * _b1.x
    let x1 = 3 * (_b1.x - _b0.x)
    let x0 = _b0.x
    
    let y3 = _b3.y - _b0.y + 3 * (_b1.y - _b2.y)
    let y2 = 3 * (_b2.y + _b0.y) - 6 * _b1.y
    let y1 = 3 * (_b1.y - _b0.y)
    let y0 = _b0.y
    
    let a = x3 * x3 + y3 * y3
    let b = 2 * (x3 * x2 + y3 * y2)
    let c = 2 * (x3 * x1 + y3 * y1) + x2 * x2 + y2 * y2
    let d = 2 * (x3 * x0 + x2 * x1 + y3 * y0 + y2 * y1)
    let e = 2 * (x2 * x0 + y2 * y0) + x1 * x1 + y1 * y1
    let f = 2 * (x1 * x0 + y1 * y0)
    let g = x0 * x0 + y0 * y0 - 1
    
    return Polynomial(g, f, e, d, c, b, a).roots
}

public func CubicQuadBezierIntersect(c0: Point, _ c1: Point, _ c2: Point, _ c3: Point, _ q0: Point, _ q1: Point, _ q2: Point) -> [Double] {
    
    let u0: Polynomial = [
        c0.x - q0.x,
        3 * (c1.x - c0.x),
        3 * (c2.x + c0.x) - 6 * c1.x,
        c3.x - c0.x + 3 * (c1.x - c2.x)
    ]
    let u1 = 2 * (q0.x - q1.x)
    let u2 = 2 * q1.x - q0.x - q2.x
    
    let v0: Polynomial = [
        c0.y - q0.y,
        3 * (c1.y - c0.y),
        3 * (c2.y + c0.y) - 6 * c1.y,
        c3.y - c0.y + 3 * (c1.y - c2.y)
    ]
    let v1 = 2 * (q0.y - q1.y)
    let v2 = 2 * q1.y - q0.y - q2.y
    
    // Bézout matrix
    let m00 = u2 * v1 - u1 * v2
    let m01 = u2 * v0 - u0 * v2
    let m10 = m01
    let m11 = u1 * v0 - u0 * v1
    
    let det = m00 * m11 - m01 * m10
    
    return det.roots
}

public func CubicBeziersIntersect(c0: Point, _ c1: Point, _ c2: Point, _ c3: Point, _ c4: Point, _ c5: Point, _ c6: Point, _ c7: Point) -> [Double] {
    
    let u0: Polynomial = [
        c0.x - c4.x,
        3 * (c1.x - c0.x),
        3 * (c2.x + c0.x) - 6 * c1.x,
        c3.x - c0.x + 3 * (c1.x - c2.x)
    ]
    let u1 = 3 * (c4.x - c5.x)
    let u2 = 6 * c5.x - 3 * (c6.x + c4.x)
    let u3 = c4.x - c7.x + 3 * (c6.x - c5.x)
    
    let v0: Polynomial = [
        c0.y - c4.y,
        3 * (c1.y - c0.y),
        3 * (c2.y + c0.y) - 6 * c1.y,
        c3.y - c0.y + 3 * (c1.y - c2.y)
    ]
    let v1 = 3 * (c4.y - c5.y)
    let v2 = 6 * c5.y - 3 * (c6.y + c4.y)
    let v3 = c4.y - c7.y + 3 * (c6.y - c5.y)
    
    // Bézout matrix
    let m00 = u3 * v2 - u2 * v3
    let m01 = u3 * v1 - u1 * v3
    let m02 = u3 * v0 - u0 * v3
    let m10 = m01
    let m11 = u2 * v1 - u1 * v2 + m02
    let m12 = u2 * v0 - u0 * v2
    let m20 = m02
    let m21 = m12
    let m22 = u1 * v0 - u0 * v1
    
    let a = m11 * m22 - m12 * m21
    let b = m12 * m20 - m10 * m22
    let c = m10 * m21 - m11 * m20
    let det = m00 * a + m01 * b + m02 * c
    
    return det.roots
}
