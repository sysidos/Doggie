//
//  GPUContext.swift
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

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
private struct GPUContextStyles {
    
    static let defaultShadowColor = CIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0 / 3.0)
    
    var opacity: Double = 1
    var transform: SDTransform = SDTransform.identity
    
    var shouldAntialias: Bool = true
    var antialias: Int = 5
    
    var shadowColor: CIColor = GPUContextStyles.defaultShadowColor
    var shadowOffset: Size = Size()
    var shadowBlur: Double = 0
    
    var blendKernel: CIBlendKernel = .sourceOver
    
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
private struct GraphicState {
    
    var clip: CIImage?
    
    var styles: GPUContextStyles
    
    init(context: GPUContext) {
        self.clip = context.state.clip
        self.styles = context.styles
    }
    
    func apply(to context: GPUContext) {
        context.state.clip = self.clip
        context.styles = self.styles
    }
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
private struct GPUContextState {
    
    var clip: CIImage?
    
    var isDirty: Bool = false
    
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
public class GPUContext {
    
    public let width: Int
    
    public let height: Int
    
    public private(set) var image: CIImage {
        didSet {
            image = image.cropped(to: CGRect(x: 0, y: 0, width: width, height: height))
        }
    }
    
    fileprivate var state: GPUContextState = GPUContextState()
    
    fileprivate var styles: GPUContextStyles = GPUContextStyles()
    private var graphicStateStack: [GraphicState] = []
    
    private var next: GPUContext?
    
    public init(width: Int, height: Int, image: CIImage = CIImage.empty()) {
        self.width = width
        self.height = height
        self.image = image.cropped(to: CGRect(x: 0, y: 0, width: width, height: height))
    }
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
extension GPUContext {
    
    private convenience init(copyStates context: GPUContext) {
        self.init(width: context.width, height: context.height)
        self.styles = context.styles
        self.styles.opacity = 1
        self.styles.shadowColor = GPUContextStyles.defaultShadowColor
        self.styles.shadowOffset = Size()
        self.styles.shadowBlur = 0
        self.styles.blendKernel = .sourceOver
    }
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
extension GPUContext {
    
    private static let black: CIImage = {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) { return CIImage.black }
        return CIImage(color: CIColor.black)
    }()
    
    private var current_layer: GPUContext {
        return next?.current_layer ?? self
    }
    
    public func clone() -> GPUContext {
        let clone = GPUContext(width: self.width, height: self.height, image: self.image)
        clone.state = self.state
        clone.styles = self.styles
        clone.graphicStateStack = self.graphicStateStack
        clone.next = self.next?.clone()
        return clone
    }
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
extension GPUContext {
    
    public func clearClipBuffer(with value: Double = 1) {
        switch value {
        case 1: current_layer.state.clip = nil
        case 0: current_layer.state.clip = GPUContext.black.cropped(to: CGRect(x: 0, y: 0, width: width, height: height))
        default:
            let color = CIColor(red: CGFloat(value), green: CGFloat(value), blue: CGFloat(value), alpha: 1)
            current_layer.state.clip = CIImage(color: color).cropped(to: CGRect(x: 0, y: 0, width: width, height: height))
        }
    }
    
    public func resetClip() {
        self.clearClipBuffer(with: 1)
    }
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
extension GPUContext {
    
    public func saveGraphicState() {
        graphicStateStack.append(GraphicState(context: current_layer))
    }
    
    public func restoreGraphicState() {
        graphicStateStack.popLast()?.apply(to: current_layer)
    }
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
extension GPUContext {
    
    public var opacity: Double {
        get {
            return current_layer.styles.opacity
        }
        set {
            current_layer.styles.opacity = newValue
        }
    }
    
    public var transform: SDTransform {
        get {
            return current_layer.styles.transform
        }
        set {
            current_layer.styles.transform = newValue
        }
    }
    
    public var shouldAntialias: Bool {
        get {
            return current_layer.styles.shouldAntialias
        }
        set {
            current_layer.styles.shouldAntialias = newValue
        }
    }
    public var antialias: Int {
        get {
            return current_layer.styles.antialias
        }
        set {
            current_layer.styles.antialias = max(1, newValue)
        }
    }
    
    public var shadowColor: CIColor {
        get {
            return current_layer.styles.shadowColor
        }
        set {
            current_layer.styles.shadowColor = newValue
        }
    }
    
    public var shadowOffset: Size {
        get {
            return current_layer.styles.shadowOffset
        }
        set {
            current_layer.styles.shadowOffset = newValue
        }
    }
    
    public var shadowBlur: Double {
        get {
            return current_layer.styles.shadowBlur
        }
        set {
            current_layer.styles.shadowBlur = newValue
        }
    }
    
    public var blendKernel: CIBlendKernel {
        get {
            return current_layer.styles.blendKernel
        }
        set {
            current_layer.styles.blendKernel = newValue
        }
    }
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
extension GPUContext {
    
    private func apply_clip(_ image: CIImage) -> CIImage {
        guard let clip = current_layer.state.clip else { return image }
        return image.applyingFilter("CIBlendWithMask", parameters: [kCIInputBackgroundImageKey: CIImage.empty(), kCIInputMaskImageKey: clip])
    }
    
    private func blend_layer(_ layer: CIImage) -> CIImage? {
        return blendKernel.apply(foreground: layer, background: current_layer.image)
    }
    
    private func draw_layer(_ layer: CIImage) {
        
        var layer = layer
        
        if shadowColor.alpha > 0 && shadowBlur > 0 {
            
            if #available(macOS 10.14, iOS 12.0, tvOS 12.0, *) {
                layer = layer.insertingIntermediate()
            }
            
            let shadow_color = CIImage(color: shadowColor)
            let shadow = layer.applyingGaussianBlur(sigma: 0.5 * shadowBlur).transformed(by: .translate(x: shadowOffset.width, y: shadowOffset.height))
            
            let image = shadow_color.applyingFilter("CIBlendWithAlphaMask", parameters: [
                kCIInputBackgroundImageKey: CIImage.empty(),
                kCIInputMaskImageKey: shadow,
            ])
            
            current_layer.image = blendKernel.apply(foreground: self.apply_clip(image), background: current_layer.image) ?? current_layer.image
        }
        
        current_layer.image = blendKernel.apply(foreground: self.apply_clip(layer), background: current_layer.image) ?? current_layer.image
    }
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
extension GPUContext {
    
    public func beginTransparencyLayer() {
        
        if let next = self.next {
            
            next.beginTransparencyLayer()
            
        } else {
            
            let width = self.width
            let height = self.height
            
            if width == 0 || height == 0 {
                return
            }
            
            self.next = GPUContext(copyStates: self)
        }
    }
    
    public func endTransparencyLayer() {
        
        guard let next = self.next else { return }
        
        if next.next != nil {
            
            next.endTransparencyLayer()
            
        } else {
            
            let width = self.width
            let height = self.height
            
            self.next = nil
            
            if width == 0 || height == 0 {
                return
            }
            
            guard next.state.isDirty else { return }
            
            self.draw_layer(next.image)
        }
    }
    
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
extension GPUContext {
    
    public func draw(shape: Shape, winding: Shape.WindingRule, color: CIColor) {
        
        if shape.reduce(0, { $0 + $1.count }) == 0 {
            return
        }
        
        var shape = shape
        shape.transform *= self.transform
        
        if width == 0 || height == 0 || shape.transform.determinant.almostZero() {
            return
        }
        
        let extent = Rect(x: 0, y: 0, width: width, height: height)
        
        guard shape.boundary.isIntersect(extent) else { return }
        guard let mask = try? CGPathProcessorKernel.apply(withExtent: CGRect(extent), path: shape.cgPath, rule: .winding) else { return }
        
        let image = CIImage(color: color).applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: CIImage.empty(),
            kCIInputMaskImageKey: mask,
        ])
        
        self.draw_layer(image)
    }
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
extension GPUContext {
    
    public func draw(image: CIImage, transform: SDTransform) {
        self.draw_layer(image.transformed(by: transform * self.transform))
    }
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
extension GPUContext {
    
    public func clip(shape: Shape, winding: Shape.WindingRule) {
        
        self.clearClipBuffer(with: 0)
        
        if shape.reduce(0, { $0 + $1.count }) == 0 {
            return
        }
        
        var shape = shape
        shape.transform *= self.transform
        
        if width == 0 || height == 0 || shape.transform.determinant.almostZero() {
            return
        }
        
        let extent = Rect(x: 0, y: 0, width: width, height: height)
        
        guard shape.boundary.isIntersect(extent) else { return }
        guard var clip = try? CGPathProcessorKernel.apply(withExtent: CGRect(extent), path: shape.cgPath, rule: .winding) else { return }
        
        if #available(macOS 10.14, iOS 12.0, tvOS 12.0, *) {
            clip = clip.insertingIntermediate()
        }
        
        current_layer.state.clip = clip
    }
}

@available(macOS 10.13, iOS 11.0, tvOS 11.0, *)
extension GPUContext {
    
    public func drawClip(body: (GPUContext) throws -> Void) rethrows {
        
        let width = self.width
        let height = self.height
        
        if width == 0 || height == 0 {
            return
        }
        
        let _clip = GPUContext(copyStates: current_layer)
        
        try body(_clip)
        
        if _clip.state.isDirty {
            
            let black = GPUContext.black
            var clip = _clip.image.composited(over: black).cropped(to: CGRect(x: 0, y: 0, width: width, height: height))
            
            if #available(macOS 10.14, iOS 12.0, tvOS 12.0, *) {
                clip = clip.insertingIntermediate()
            }
            
            current_layer.state.clip = clip
            
        } else {
            current_layer.clearClipBuffer(with: 0)
        }
    }
}

#endif
