//
//  Color.swift
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

public struct Color<Model : ColorModelProtocol> {
    
    public var colorSpace: ColorSpace<Model>
    
    public var color: Model
    
    public var opacity: Double
    
    @_inlineable
    public init<C : ColorSpaceProtocol, P : ColorPixelProtocol>(colorSpace: C, color: P) where C.Model == Model, C.Model == P.Model {
        self.colorSpace = ColorSpace(colorSpace)
        self.color = color.color
        self.opacity = color.opacity
    }
    
    @_inlineable
    public init<C : ColorSpaceProtocol>(colorSpace: C, color: Model, opacity: Double = 1) where C.Model == Model {
        self.colorSpace = ColorSpace(colorSpace)
        self.color = color
        self.opacity = opacity
    }
}

extension Color where Model == GrayColorModel {
    
    @_inlineable
    public init<C : ColorSpaceProtocol>(colorSpace: C, white: Double, opacity: Double = 1) where C.Model == Model {
        self.init(colorSpace: colorSpace, color: GrayColorModel(white: white), opacity: opacity)
    }
}

extension Color where Model == RGBColorModel {
    
    @_inlineable
    public init<C : ColorSpaceProtocol>(colorSpace: C, red: Double, green: Double, blue: Double, opacity: Double = 1) where C.Model == Model {
        self.init(colorSpace: colorSpace, color: RGBColorModel(red: red, green: green, blue: blue), opacity: opacity)
    }
}

extension Color where Model == CMYKColorModel {
    
    @_inlineable
    public init<C : ColorSpaceProtocol>(colorSpace: C, cyan: Double, magenta: Double, yellow: Double, black: Double, opacity: Double = 1) where C.Model == Model {
        self.init(colorSpace: colorSpace, color: CMYKColorModel(cyan: cyan, magenta: magenta, yellow: yellow, black: black), opacity: opacity)
    }
}

extension Color where Model == GrayColorModel {
    
    @_inlineable
    public var white: Double {
        get {
            return color.white
        }
        set {
            color.white = newValue
        }
    }
}

extension Color where Model == RGBColorModel {
    
    @_inlineable
    public var red: Double {
        get {
            return color.red
        }
        set {
            color.red = newValue
        }
    }
    
    @_inlineable
    public var green: Double {
        get {
            return color.green
        }
        set {
            color.green = newValue
        }
    }
    
    @_inlineable
    public var blue: Double {
        get {
            return color.blue
        }
        set {
            color.blue = newValue
        }
    }
}

extension Color where Model == RGBColorModel {
    
    @_inlineable
    public var hue: Double {
        get {
            return color.hue
        }
        set {
            color.hue = newValue
        }
    }
    
    @_inlineable
    public var saturation: Double {
        get {
            return color.saturation
        }
        set {
            color.saturation = newValue
        }
    }
    
    @_inlineable
    public var brightness: Double {
        get {
            return color.brightness
        }
        set {
            color.brightness = newValue
        }
    }
}

extension Color where Model == CMYKColorModel {
    
    @_inlineable
    public var cyan: Double {
        get {
            return color.cyan
        }
        set {
            color.cyan = newValue
        }
    }
    
    @_inlineable
    public var magenta: Double {
        get {
            return color.magenta
        }
        set {
            color.magenta = newValue
        }
    }
    
    @_inlineable
    public var yellow: Double {
        get {
            return color.yellow
        }
        set {
            color.yellow = newValue
        }
    }
    
    @_inlineable
    public var black: Double {
        get {
            return color.black
        }
        set {
            color.black = newValue
        }
    }
}

extension Color {
    
    @_inlineable
    public func convert<C : ColorSpaceProtocol>(to colorSpace: C) -> Color<C.Model> {
        return Color<C.Model>(colorSpace: colorSpace, color: self.colorSpace.convert(color, to: colorSpace), opacity: opacity)
    }
}

extension Color {
    
    @_inlineable
    public func blended<C>(source: Color<C>, blendMode: ColorBlendMode, compositingMode: ColorCompositingMode) -> Color {
        let source = source.convert(to: colorSpace)
        let color = ColorPixel(color: self.color, opacity: self.opacity).blended(source: ColorPixel(color: source.color, opacity: source.opacity), blendMode: blendMode, compositingMode: compositingMode)
        return Color(colorSpace: colorSpace, color: color.color, opacity: color.opacity)
    }
    
    @_inlineable
    public mutating func blend<C>(source: Color<C>, blendMode: ColorBlendMode, compositingMode: ColorCompositingMode) {
        self = self.blended(source: source, blendMode: blendMode, compositingMode: compositingMode)
    }
}
