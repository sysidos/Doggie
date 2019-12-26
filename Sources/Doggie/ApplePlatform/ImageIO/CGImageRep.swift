//
//  CGImageRep.swift
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

#if canImport(CoreGraphics) && canImport(ImageIO)

protocol CGImageRepBase {
    
    var width: Int { get }
    
    var height: Int { get }
    
    var resolution: Resolution { get }
    
    var mediaType: ImageRep.MediaType? { get }
    
    var numberOfPages: Int { get }
    
    var properties: [CFString : Any] { get }
    
    func page(_ index: Int) -> CGImageRepBase
    
    var cgImage: CGImage? { get }
    
    func auxiliaryDataInfo(_ type: String) -> [String : AnyObject]?
    
    func copy(to destination: CGImageDestination, properties: [CFString: Any])
}

public struct CGImageRep {
    
    let base: CGImageRepBase
    
    private let cache = Cache()
    
    private init(base: CGImageRepBase) {
        self.base = base
    }
}

extension CGImageRep {
    
    @usableFromInline
    final class Cache {
        
        let lck = SDLock()
        
        var image: CGImage?
        var pages: [Int: CGImageRep]
        
        @usableFromInline
        init() {
            self.pages = [:]
        }
    }
}

extension CGImageRep {
    
    public static var supportedMediaTypes: [ImageRep.MediaType] {
        let types = CGImageSourceCopyTypeIdentifiers() as? [String] ?? []
        return types.map { ImageRep.MediaType(rawValue: $0) }
    }
    
    public static var supportedDestinationMediaTypes: [ImageRep.MediaType] {
        let types = CGImageDestinationCopyTypeIdentifiers() as? [String] ?? []
        return types.map { ImageRep.MediaType(rawValue: $0) }
    }
}

extension CGImageRep {
    
    public init?(url: URL) {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil).flatMap(_CGImageSourceImageRepBase.init) else { return nil }
        self.base = source
    }
    
    public init?(data: Data) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil).flatMap(_CGImageSourceImageRepBase.init) else { return nil }
        self.base = source
    }
    
    public init?(provider: CGDataProvider) {
        guard let source = CGImageSourceCreateWithDataProvider(provider, nil).flatMap(_CGImageSourceImageRepBase.init) else { return nil }
        self.base = source
    }
}

extension CGImageRep {
    
    public init(cgImage: CGImage, resolution: Resolution = .default) {
        self.base = _CGImageRepBase(image: cgImage, resolution: resolution)
    }
}

extension CGImageRep {
    
    public var numberOfPages: Int {
        return base.numberOfPages
    }
    
    public func page(_ index: Int) -> CGImageRep {
        return cache.lck.synchronized {
            if cache.pages[index] == nil {
                cache.pages[index] = CGImageRep(base: base.page(index))
            }
            return cache.pages[index]!
        }
    }
    
    public var cgImage: CGImage? {
        return cache.lck.synchronized {
            if cache.image == nil {
                cache.image = base.cgImage
            }
            return cache.image
        }
    }
    
    public func auxiliaryDataInfo(_ type: String) -> [String : AnyObject]? {
        return base.auxiliaryDataInfo(type)
    }
}

extension CGImageRep {
    
    public var width: Int {
        return base.width
    }
    
    public var height: Int {
        return base.height
    }
    
    public var resolution: Resolution {
        return base.resolution
    }
}

extension CGImageRep {
    
    public var properties: [CFString : Any] {
        return base.properties
    }
}

extension CGImageRep {
    
    public var mediaType: ImageRep.MediaType? {
        return base.mediaType
    }
}

#endif
