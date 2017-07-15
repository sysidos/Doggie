//
//  ICCColorSpace.swift
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

@_versioned
let PCSXYZ = CIEXYZColorSpace(white: Point(x: 0.34567, y: 0.35850))

@_versioned
protocol PCSColorModel : ColorModelProtocol {
    
    var luminance: Double { get set }
    
    static func * (lhs: Self, rhs: Matrix) -> Self
    
    static func *= (lhs: inout Self, rhs: Matrix)
}

extension XYZColorModel : PCSColorModel {
    
}

extension LabColorModel : PCSColorModel {
    
    @_versioned
    @_inlineable
    var luminance: Double {
        get {
            return lightness
        }
        set {
            lightness = newValue
        }
    }
    
    @_versioned
    @_inlineable
    static func * (lhs: LabColorModel, rhs: Matrix) -> LabColorModel {
        return LabColorModel(lightness: lhs.lightness * rhs.a + lhs.a * rhs.b + lhs.b * rhs.c + rhs.d, a: lhs.lightness * rhs.e + lhs.a * rhs.f + lhs.b * rhs.g + rhs.h, b: lhs.lightness * rhs.i + lhs.a * rhs.j + lhs.b * rhs.k + rhs.l)
    }
    
    @_versioned
    @_inlineable
    static func *= (lhs: inout LabColorModel, rhs: Matrix) {
        lhs = lhs * rhs
    }
}

@_versioned
protocol NonnormalizedColorModel {
    
    static func rangeOfComponent(_ i: Int) -> ClosedRange<Double>
}

extension LuvColorModel : NonnormalizedColorModel {
    
    @_versioned
    @_inlineable
    static func rangeOfComponent(_ i: Int) -> ClosedRange<Double> {
        switch i {
        case 0: return 0...100
        default: return -128...128
        }
    }
}

extension LabColorModel : NonnormalizedColorModel {
    
    @_versioned
    @_inlineable
    static func rangeOfComponent(_ i: Int) -> ClosedRange<Double> {
        switch i {
        case 0: return 0...100
        default: return -128...128
        }
    }
}

@_versioned
@_fixed_layout
struct ICCColorSpace<Model : ColorModelProtocol, Connection : ColorSpaceBaseProtocol> : ColorSpaceBaseProtocol where Connection.Model : PCSColorModel {
    
    @_versioned
    let _iccData: Data
    
    let profile: iccProfile
    
    @_versioned
    let connection : Connection
    
    @_versioned
    let cieXYZ : CIEXYZColorSpace
    
    @_versioned
    let a2b: iccTransform
    
    @_versioned
    let b2a: iccTransform
    
    @_versioned
    let chromaticAdaptationMatrix: Matrix
    
    init(iccData: Data, profile: iccProfile, connection : Connection, cieXYZ : CIEXYZColorSpace, a2b: iccTransform, b2a: iccTransform, chromaticAdaptationMatrix: Matrix) {
        self._iccData = iccData
        self.profile = profile
        self.connection = connection
        self.cieXYZ = cieXYZ
        self.a2b = a2b
        self.b2a = b2a
        self.chromaticAdaptationMatrix = chromaticAdaptationMatrix
    }
}

extension ICCColorSpace {
    
    @_versioned
    var iccData: Data? {
        return _iccData
    }
}

extension ICCColorSpace {
    
    @_versioned
    var localizedName: String? {
        
        if let description = profile[.ProfileDescription] {
            
            if let desc = description.text {
                return desc
            }
            if let desc = description.textDescription {
                return desc.ascii ?? desc.unicode
            }
            
            let language = Locale.current.languageCode ?? "en"
            let country = Locale.current.regionCode ?? "US"
            
            if let desc = description.multiLocalizedUnicode {
                return desc.first(where: { $0.language.description == language && $0.country.description == country })?.2 ?? desc.first(where: { $0.language.description == language })?.2 ?? desc.first?.2
            }
        }
        
        return nil
    }
}

extension AnyColorSpace {
    
    public enum ParserError : Error {
        
        case endOfData
        case invalidFormat(message: String)
        case unsupported(message: String)
    }
    
    public init(iccData: Data) throws {
        
        let profile = try iccProfile(iccData)
        
        switch profile.header.colorSpace {
            
        case .XYZ: self._base = try ColorSpace<XYZColorModel>(iccData: iccData, profile: profile)
        case .Lab: self._base = try ColorSpace<LabColorModel>(iccData: iccData, profile: profile)
        case .Luv: self._base = try ColorSpace<LuvColorModel>(iccData: iccData, profile: profile)
        case .YCbCr: self._base = try ColorSpace<Device3ColorModel>(iccData: iccData, profile: profile)
        case .Yxy: self._base = try ColorSpace<Device3ColorModel>(iccData: iccData, profile: profile)
        case .Rgb: self._base = try ColorSpace<RGBColorModel>(iccData: iccData, profile: profile)
        case .Gray: self._base = try ColorSpace<GrayColorModel>(iccData: iccData, profile: profile)
        case .Hsv: self._base = try ColorSpace<Device3ColorModel>(iccData: iccData, profile: profile)
        case .Hls: self._base = try ColorSpace<Device3ColorModel>(iccData: iccData, profile: profile)
        case .Cmyk: self._base = try ColorSpace<CMYKColorModel>(iccData: iccData, profile: profile)
        case .Cmy: self._base = try ColorSpace<CMYColorModel>(iccData: iccData, profile: profile)
            
        case .Named: throw AnyColorSpace.ParserError.unsupported(message: "ColorSpace: \(profile.header.colorSpace)")
            
        case .color2: self._base = try ColorSpace<Device2ColorModel>(iccData: iccData, profile: profile)
        case .color3: self._base = try ColorSpace<Device3ColorModel>(iccData: iccData, profile: profile)
        case .color4: self._base = try ColorSpace<Device4ColorModel>(iccData: iccData, profile: profile)
        case .color5: self._base = try ColorSpace<Device5ColorModel>(iccData: iccData, profile: profile)
        case .color6: self._base = try ColorSpace<Device6ColorModel>(iccData: iccData, profile: profile)
        case .color7: self._base = try ColorSpace<Device7ColorModel>(iccData: iccData, profile: profile)
        case .color8: self._base = try ColorSpace<Device8ColorModel>(iccData: iccData, profile: profile)
        case .color9: self._base = try ColorSpace<Device9ColorModel>(iccData: iccData, profile: profile)
        case .color10: self._base = try ColorSpace<Device10ColorModel>(iccData: iccData, profile: profile)
        case .color11: self._base = try ColorSpace<Device11ColorModel>(iccData: iccData, profile: profile)
        case .color12: self._base = try ColorSpace<Device12ColorModel>(iccData: iccData, profile: profile)
        case .color13: self._base = try ColorSpace<Device13ColorModel>(iccData: iccData, profile: profile)
        case .color14: self._base = try ColorSpace<Device14ColorModel>(iccData: iccData, profile: profile)
        case .color15: self._base = try ColorSpace<Device15ColorModel>(iccData: iccData, profile: profile)
        default: throw AnyColorSpace.ParserError.unsupported(message: "ColorSpace: \(profile.header.colorSpace)")
        }
    }
}

extension ColorSpace {
    
    init(iccData: Data, profile: iccProfile) throws {
        
        func check(_ a2bCurve: iccTransform, _ b2aCurve: iccTransform) throws {
            
            switch a2bCurve {
            case let .LUT0(_, i, lut, o):
                if lut.inputChannels != Model.numberOfComponents || lut.outputChannels != 3 {
                    throw AnyColorSpace.ParserError.invalidFormat(message: "Invalid LUT size.")
                }
                if i.channels != Model.numberOfComponents {
                    throw AnyColorSpace.ParserError.invalidFormat(message: "Invalid LUT size.")
                }
                if o.channels != 3 {
                    throw AnyColorSpace.ParserError.invalidFormat(message: "Invalid LUT size.")
                }
            case .LUT1, .LUT2:
                if Model.numberOfComponents != 3 {
                    throw AnyColorSpace.ParserError.invalidFormat(message: "Invalid LUT size.")
                }
            case let .LUT3(_, lut, A):
                if lut.inputChannels != Model.numberOfComponents || lut.outputChannels != 3 {
                    throw AnyColorSpace.ParserError.invalidFormat(message: "Invalid LUT size.")
                }
                if A.count != Model.numberOfComponents {
                    throw AnyColorSpace.ParserError.invalidFormat(message: "Invalid LUT size.")
                }
            case let .LUT4(_, _, _, lut, A):
                if lut.inputChannels != Model.numberOfComponents || lut.outputChannels != 3 {
                    throw AnyColorSpace.ParserError.invalidFormat(message: "Invalid LUT size.")
                }
                if A.count != Model.numberOfComponents {
                    throw AnyColorSpace.ParserError.invalidFormat(message: "Invalid LUT size.")
                }
            default: break
            }
            
            switch b2aCurve {
            case let .LUT0(_, i, lut, o):
                if lut.inputChannels != 3 || lut.outputChannels != Model.numberOfComponents {
                    throw AnyColorSpace.ParserError.invalidFormat(message: "Invalid LUT size.")
                }
                if i.channels != 3 {
                    throw AnyColorSpace.ParserError.invalidFormat(message: "Invalid LUT size.")
                }
                if o.channels != Model.numberOfComponents {
                    throw AnyColorSpace.ParserError.invalidFormat(message: "Invalid LUT size.")
                }
            case .LUT1, .LUT2:
                if Model.numberOfComponents != 3 {
                    throw AnyColorSpace.ParserError.invalidFormat(message: "Invalid LUT size.")
                }
            case let .LUT3(_, lut, A):
                if lut.inputChannels != 3 || lut.outputChannels != Model.numberOfComponents {
                    throw AnyColorSpace.ParserError.invalidFormat(message: "Invalid LUT size.")
                }
                if A.count != Model.numberOfComponents {
                    throw AnyColorSpace.ParserError.invalidFormat(message: "Invalid LUT size.")
                }
            case let .LUT4(_, _, _, lut, A):
                if lut.inputChannels != 3 || lut.outputChannels != Model.numberOfComponents {
                    throw AnyColorSpace.ParserError.invalidFormat(message: "Invalid LUT size.")
                }
                if A.count != Model.numberOfComponents {
                    throw AnyColorSpace.ParserError.invalidFormat(message: "Invalid LUT size.")
                }
            default: break
            }
            
        }
        
        func ABCurve() throws -> (iccTransform, iccTransform)? {
            
            if let a2bCurve = profile[.AToB1].flatMap({ $0.transform }), let b2aCurve = profile[.BToA1].flatMap({ $0.transform }) {
                try check(a2bCurve, b2aCurve)
                return (a2bCurve, b2aCurve)
            }
            if let a2bCurve = profile[.AToB0].flatMap({ $0.transform }), let b2aCurve = profile[.BToA0].flatMap({ $0.transform }) {
                try check(a2bCurve, b2aCurve)
                return (a2bCurve, b2aCurve)
            }
            if let a2bCurve = profile[.AToB2].flatMap({ $0.transform }), let b2aCurve = profile[.BToA2].flatMap({ $0.transform }){
                try check(a2bCurve, b2aCurve)
                return (a2bCurve, b2aCurve)
            }
            
            return nil
        }
        
        let a2b: iccTransform
        let b2a: iccTransform
        
        switch Model.numberOfComponents {
        case 1:
            
            if let curve = profile[.GrayTRC] {
                
                let kTRC = curve.curve ?? .identity
                
                a2b = .monochrome(kTRC)
                b2a = .monochrome(kTRC.inverse)
                
            } else if let (a2bCurve, b2aCurve) = try ABCurve() {
                
                a2b = a2bCurve
                b2a = b2aCurve
                
            } else {
                throw AnyColorSpace.ParserError.invalidFormat(message: "LUT not found.")
            }
            
        case 3 where profile.header.pcs == .XYZ:
            
            if let red = profile[.RedColorant]?.XYZArray?.first, let green = profile[.GreenColorant]?.XYZArray?.first, let blue = profile[.BlueColorant]?.XYZArray?.first {
                
                let rTRC = profile[.RedTRC].flatMap { $0.curve } ?? .identity
                let gTRC = profile[.GreenTRC].flatMap { $0.curve } ?? .identity
                let bTRC = profile[.BlueTRC].flatMap { $0.curve } ?? .identity
                
                let matrix = Matrix(a: red.x.representingValue, b: green.x.representingValue, c: blue.x.representingValue, d: 0,
                                    e: red.y.representingValue, f: green.y.representingValue, g: blue.y.representingValue, h: 0,
                                    i: red.z.representingValue, j: green.z.representingValue, k: blue.z.representingValue, l: 0)
                
                a2b = .matrix(matrix, (rTRC, gTRC, bTRC))
                b2a = .matrix(matrix.inverse, (rTRC.inverse, gTRC.inverse, bTRC.inverse))
                
            } else if let (a2bCurve, b2aCurve) = try ABCurve() {
                
                a2b = a2bCurve
                b2a = b2aCurve
                
            } else {
                throw AnyColorSpace.ParserError.invalidFormat(message: "LUT not found.")
            }
            
        default:
            
            if let (a2bCurve, b2aCurve) = try ABCurve() {
                
                a2b = a2bCurve
                b2a = b2aCurve
                
            } else {
                throw AnyColorSpace.ParserError.invalidFormat(message: "LUT not found.")
            }
        }
        
        let cieXYZ: CIEXYZColorSpace
        
        if let white = profile[.MediaWhitePoint]?.XYZArray?.first {
            if let black = profile[.MediaBlackPoint]?.XYZArray?.first {
                if let luminance = profile[.Luminance]?.XYZArray?.first?.y {
                    cieXYZ = CIEXYZColorSpace(white: XYZColorModel(x: white.x.representingValue, y: white.y.representingValue, z: white.z.representingValue), black: XYZColorModel(x: black.x.representingValue, y: black.y.representingValue, z: black.z.representingValue), luminance: luminance.representingValue)
                } else {
                    cieXYZ = CIEXYZColorSpace(white: XYZColorModel(x: white.x.representingValue, y: white.y.representingValue, z: white.z.representingValue), black: XYZColorModel(x: black.x.representingValue, y: black.y.representingValue, z: black.z.representingValue))
                }
            } else {
                if let luminance = profile[.Luminance]?.XYZArray?.first?.y {
                    cieXYZ = CIEXYZColorSpace(white: XYZColorModel(x: white.x.representingValue, y: white.y.representingValue, z: white.z.representingValue), luminance: luminance.representingValue)
                } else {
                    cieXYZ = CIEXYZColorSpace(white: XYZColorModel(x: white.x.representingValue, y: white.y.representingValue, z: white.z.representingValue))
                }
            }
        } else {
            throw AnyColorSpace.ParserError.invalidFormat(message: "MediaWhitePoint not found.")
        }
        
        let chromaticAdaptationMatrix = cieXYZ.chromaticAdaptationMatrix(to: PCSXYZ, .default)
        
        switch profile.header.pcs {
        case .XYZ: self.base = ICCColorSpace<Model, CIEXYZColorSpace>(iccData: iccData, profile: profile, connection: PCSXYZ, cieXYZ: cieXYZ, a2b: a2b, b2a: b2a, chromaticAdaptationMatrix: chromaticAdaptationMatrix)
        case .Lab: self.base = ICCColorSpace<Model, CIELabColorSpace>(iccData: iccData, profile: profile, connection: CIELabColorSpace(PCSXYZ), cieXYZ: cieXYZ, a2b: a2b, b2a: b2a, chromaticAdaptationMatrix: chromaticAdaptationMatrix)
        default: throw AnyColorSpace.ParserError.invalidFormat(message: "Invalid PCS.")
        }
    }
}

extension ICCColorSpace {
    
    @_versioned
    @_inlineable
    func convertToLinear(_ color: Model) -> Model {
        
        var result = Model()
        
        var color = color
        
        if let _Model = Model.self as? NonnormalizedColorModel.Type {
            for i in 0..<Model.numberOfComponents {
                let upperBound = _Model.rangeOfComponent(i).upperBound
                let lowerBound = _Model.rangeOfComponent(i).lowerBound
                color.setComponent(i, (color.component(i) - lowerBound) / (upperBound - lowerBound))
            }
        }
        
        switch a2b {
        case let .monochrome(curve):
            
            result.setComponent(0, curve.eval(color.component(0)))
            
        case let .matrix(_, curve):
            
            result.setComponent(0, curve.0.eval(color.component(0)))
            result.setComponent(1, curve.1.eval(color.component(1)))
            result.setComponent(2, curve.2.eval(color.component(2)))
            
        case let .LUT0(_, curve, _, _):
            
            result = curve.eval(color)
            
        case let .LUT1(curve):
            
            result.setComponent(0, curve.0.eval(color.component(0)))
            result.setComponent(1, curve.1.eval(color.component(1)))
            result.setComponent(2, curve.2.eval(color.component(2)))
            
            if result is XYZColorModel {
                result *= 65535.0 / 32768.0
            }
            
        case let .LUT2(_, _, curve):
            
            result.setComponent(0, curve.0.eval(color.component(0)))
            result.setComponent(1, curve.1.eval(color.component(1)))
            result.setComponent(2, curve.2.eval(color.component(2)))
            
        case let .LUT3(_, _, curve):
            
            for i in 0..<Model.numberOfComponents {
                result.setComponent(i, curve[i].eval(color.component(i)))
            }
            
        case let .LUT4(_, _, _, _, curve):
            
            for i in 0..<Model.numberOfComponents {
                result.setComponent(i, curve[i].eval(color.component(i)))
            }
        }
        
        if let _Model = Model.self as? NonnormalizedColorModel.Type {
            for i in 0..<Model.numberOfComponents {
                let upperBound = _Model.rangeOfComponent(i).upperBound
                let lowerBound = _Model.rangeOfComponent(i).lowerBound
                result.setComponent(i, result.component(i) * (upperBound - lowerBound) + lowerBound)
            }
        }
        
        return result
    }
    
    @_versioned
    @_inlineable
    func convertFromLinear(_ color: Model) -> Model {
        
        var result = Model()
        
        var color = color
        
        if let _Model = Model.self as? NonnormalizedColorModel.Type {
            for i in 0..<Model.numberOfComponents {
                let upperBound = _Model.rangeOfComponent(i).upperBound
                let lowerBound = _Model.rangeOfComponent(i).lowerBound
                color.setComponent(i, (color.component(i) - lowerBound) / (upperBound - lowerBound))
            }
        }
        
        switch b2a {
        case let .monochrome(curve):
            
            result.setComponent(0, curve.eval(color.component(0)))
            
        case let .matrix(_, curve):
            
            result.setComponent(0, curve.0.eval(color.component(0)))
            result.setComponent(1, curve.1.eval(color.component(1)))
            result.setComponent(2, curve.2.eval(color.component(2)))
            
        case let .LUT0(_, _, _, curve):
            
            result = curve.eval(color)
            
        case let .LUT1(curve):
            
            if color is XYZColorModel {
                color *= 32768.0 / 65535.0
            }
            
            result.setComponent(0, curve.0.eval(color.component(0)))
            result.setComponent(1, curve.1.eval(color.component(1)))
            result.setComponent(2, curve.2.eval(color.component(2)))
            
        case let .LUT2(_, _, curve):
            
            result.setComponent(0, curve.0.eval(color.component(0)))
            result.setComponent(1, curve.1.eval(color.component(1)))
            result.setComponent(2, curve.2.eval(color.component(2)))
            
        case let .LUT3(_, _, curve):
            
            for i in 0..<Model.numberOfComponents {
                result.setComponent(i, curve[i].eval(color.component(i)))
            }
            
        case let .LUT4(_, _, _, _, curve):
            
            for i in 0..<Model.numberOfComponents {
                result.setComponent(i, curve[i].eval(color.component(i)))
            }
        }
        
        if let _Model = Model.self as? NonnormalizedColorModel.Type {
            for i in 0..<Model.numberOfComponents {
                let upperBound = _Model.rangeOfComponent(i).upperBound
                let lowerBound = _Model.rangeOfComponent(i).lowerBound
                result.setComponent(i, result.component(i) * (upperBound - lowerBound) + lowerBound)
            }
        }
        
        return result
    }
    
    @_versioned
    @_inlineable
    func convertLinearToConnection(_ color: Model) -> Connection.Model {
        
        var result = Connection.Model()
        
        var color = color
        
        if let _Model = Model.self as? NonnormalizedColorModel.Type {
            for i in 0..<Model.numberOfComponents {
                let upperBound = _Model.rangeOfComponent(i).upperBound
                let lowerBound = _Model.rangeOfComponent(i).lowerBound
                color.setComponent(i, (color.component(i) - lowerBound) / (upperBound - lowerBound))
            }
        }
        
        switch a2b {
        case .monochrome:
            
            result = self.connection._convertFromXYZ(cieXYZ.white * cieXYZ.normalizeMatrix)
            result.luminance = color.component(0)
            
        case let .matrix(matrix, _):
            
            result.setComponent(0, color.component(0))
            result.setComponent(1, color.component(1))
            result.setComponent(2, color.component(2))
            
            result *= matrix
            
        case let .LUT0(matrix, _, lut, o):
            
            result = lut.eval(color)
            
            result = o.eval(result)
            
            if result is XYZColorModel {
                result *= matrix
            }
            
        case .LUT1:
            
            result.setComponent(0, color.component(0))
            result.setComponent(1, color.component(1))
            result.setComponent(2, color.component(2))
            
        case let .LUT2(B, matrix, _):
            
            result.setComponent(0, color.component(0))
            result.setComponent(1, color.component(1))
            result.setComponent(2, color.component(2))
            
            result *= matrix
            
            result.setComponent(0, B.0.eval(result.component(0)))
            result.setComponent(1, B.1.eval(result.component(1)))
            result.setComponent(2, B.2.eval(result.component(2)))
            
            if result is XYZColorModel {
                result *= 65535.0 / 32768.0
            }
            
        case let .LUT3(B, lut, _):
            
            result = lut.eval(color)
            
            result.setComponent(0, B.0.eval(result.component(0)))
            result.setComponent(1, B.1.eval(result.component(1)))
            result.setComponent(2, B.2.eval(result.component(2)))
            
            if result is XYZColorModel {
                result *= 65535.0 / 32768.0
            }
            
        case let .LUT4(B, matrix, M, lut, _):
            
            result = lut.eval(color)
            
            result.setComponent(0, M.0.eval(result.component(0)))
            result.setComponent(1, M.1.eval(result.component(1)))
            result.setComponent(2, M.2.eval(result.component(2)))
            
            result *= matrix
            
            result.setComponent(0, B.0.eval(result.component(0)))
            result.setComponent(1, B.1.eval(result.component(1)))
            result.setComponent(2, B.2.eval(result.component(2)))
            
            if result is XYZColorModel {
                result *= 65535.0 / 32768.0
            }
        }
        
        if let _Model = Connection.Model.self as? NonnormalizedColorModel.Type {
            for i in 0..<Connection.Model.numberOfComponents {
                let upperBound = _Model.rangeOfComponent(i).upperBound
                let lowerBound = _Model.rangeOfComponent(i).lowerBound
                result.setComponent(i, result.component(i) * (upperBound - lowerBound) + lowerBound)
            }
        }
        
        return result
    }
    
    @_versioned
    @_inlineable
    func convertLinearFromConnection(_ color: Connection.Model) -> Model {
        
        var result = Model()
        
        var color = color
        
        if let _Model = Connection.Model.self as? NonnormalizedColorModel.Type {
            for i in 0..<Connection.Model.numberOfComponents {
                let upperBound = _Model.rangeOfComponent(i).upperBound
                let lowerBound = _Model.rangeOfComponent(i).lowerBound
                color.setComponent(i, (color.component(i) - lowerBound) / (upperBound - lowerBound))
            }
        }
        
        switch b2a {
        case .monochrome:
            
            result.setComponent(0, color.luminance)
            
        case let .matrix(matrix, _):
            
            color *= matrix
            
            result.setComponent(0, color.component(0))
            result.setComponent(1, color.component(1))
            result.setComponent(2, color.component(2))
            
        case let .LUT0(matrix, i, lut, _):
            
            if color is XYZColorModel {
                color *= matrix
            }
            
            color = i.eval(color)
            
            result = lut.eval(color)
            
        case .LUT1:
            
            result.setComponent(0, color.component(0))
            result.setComponent(1, color.component(1))
            result.setComponent(2, color.component(2))
            
        case let .LUT2(B, matrix, _):
            
            if color is XYZColorModel {
                color *= 32768.0 / 65535.0
            }
            
            color.setComponent(0, B.0.eval(color.component(0)))
            color.setComponent(1, B.1.eval(color.component(1)))
            color.setComponent(2, B.2.eval(color.component(2)))
            
            color *= matrix
            
            result.setComponent(0, color.component(0))
            result.setComponent(1, color.component(1))
            result.setComponent(2, color.component(2))
            
        case let .LUT3(B, lut, _):
            
            if color is XYZColorModel {
                color *= 32768.0 / 65535.0
            }
            
            color.setComponent(0, B.0.eval(color.component(0)))
            color.setComponent(1, B.1.eval(color.component(1)))
            color.setComponent(2, B.2.eval(color.component(2)))
            
            result = lut.eval(color)
            
        case let .LUT4(B, matrix, M, lut, _):
            
            if color is XYZColorModel {
                color *= 32768.0 / 65535.0
            }
            
            color.setComponent(0, B.0.eval(color.component(0)))
            color.setComponent(1, B.1.eval(color.component(1)))
            color.setComponent(2, B.2.eval(color.component(2)))
            
            color *= matrix
            
            color.setComponent(0, M.0.eval(color.component(0)))
            color.setComponent(1, M.1.eval(color.component(1)))
            color.setComponent(2, M.2.eval(color.component(2)))
            
            result = lut.eval(color)
        }
        
        if let _Model = Model.self as? NonnormalizedColorModel.Type {
            for i in 0..<Model.numberOfComponents {
                let upperBound = _Model.rangeOfComponent(i).upperBound
                let lowerBound = _Model.rangeOfComponent(i).lowerBound
                result.setComponent(i, result.component(i) * (upperBound - lowerBound) + lowerBound)
            }
        }
        
        return result
    }
    
    @_versioned
    @_inlineable
    func convertLinearToXYZ(_ color: Model) -> XYZColorModel {
        return self.connection._convertToXYZ(self.convertLinearToConnection(color)) * chromaticAdaptationMatrix.inverse
    }
    
    @_versioned
    @_inlineable
    func convertLinearFromXYZ(_ color: XYZColorModel) -> Model {
        return self.convertLinearFromConnection(self.connection._convertFromXYZ(color * chromaticAdaptationMatrix))
    }
}

