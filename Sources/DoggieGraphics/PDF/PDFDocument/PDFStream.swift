//
//  PDFStream.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2020 Susan Cheng. All rights reserved.
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

@frozen
public struct PDFStream: Hashable {
    
    @usableFromInline
    var dictionary: [PDFName: PDFObject]
    
    public var data: Data {
        didSet {
            self.dictionary["Length"] = PDFObject(data.count)
        }
    }
    
    @usableFromInline
    let cache = Cache()
    
    @inlinable
    public init(dictionary: [PDFName: PDFObject] = [:], data: Data = Data()) {
        self.dictionary = dictionary
        self.data = data
        self.dictionary["Length"] = PDFObject(data.count)
    }
}

extension PDFStream {
    
    @usableFromInline
    class Cache {
        
        let lck = SDLock()
        
        var image: AnyImage?
        
        var mask: AnyImage?
        
        @usableFromInline
        init() { }
    }
}

extension PDFStream {
    
    public static func == (lhs: PDFStream, rhs: PDFStream) -> Bool {
        return lhs.dictionary == rhs.dictionary && lhs.data == rhs.data
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(dictionary)
        hasher.combine(data)
    }
}

extension PDFStream {
    
    @inlinable
    public var count: Int {
        return dictionary.count
    }
    
    @inlinable
    public var keys: Dictionary<PDFName, PDFObject>.Keys {
        return dictionary.keys
    }
    
    @inlinable
    public subscript(key: PDFName) -> PDFObject {
        get {
            return dictionary[key] ?? nil
        }
        set {
            dictionary[key] = newValue.isNil ? nil : newValue
        }
    }
}

extension PDFObject {
    
    var filters: [PDFName]? {
        return self.array?.compactMap { $0.name } ?? self.name.map { [$0] }
    }
}

extension PDFStream {
    
    private func decode(_ data: Data, _ filter: PDFName) -> Data? {
        
        switch filter {
            
        case "ASCIIHexDecode":
            
            var data = data
            return ASCIIHexFilter.decode(&data)
            
        case "ASCII85Decode":
            
            var data = data
            return ASCII85Filter.decode(&data)
            
        case "LZWDecode":
            
            return nil
            
        case "FlateDecode":
            
            return try? Inflate().process(data)
            
        case "RunLengthDecode":
            
            return nil
            
        default: return nil
        }
    }
    
    func decode() -> Data? {
        guard let filters = self["Filter"].filters else { return data }
        return filters.reduce(data) { data, filter in data.flatMap { self.decode($0, filter) } }
    }
}

extension PDFStream {
    
    func compressed(_ properties: [PDFContext.PropertyKey: Any]) -> PDFStream {
        
        guard dictionary["Filter"] == nil else { return self }
        
        var copy = self
        
        let deflate_level = properties[.deflateLevel] as? Deflate.Level ?? .default
        
        if deflate_level != .none, let compressed = try? Deflate(level: deflate_level, windowBits: 15).process(copy.data) {
            copy.dictionary["Filter"] = PDFObject("FlateDecode" as PDFName)
            copy.data = compressed
        }
        
        return copy
    }
}

extension PDFStream {
    
    @inlinable
    public func encode(_ data: inout Data) {
        data.append(utf8: "<<\n")
        for (name, object) in dictionary {
            name.encode(&data)
            data.append(utf8: " ")
            object.encode(&data)
            data.append(utf8: "\n")
        }
        data.append(utf8: ">>\n")
        data.append(utf8: "stream\n")
        data.append(self.data)
        data.append(utf8: "\nendstream")
    }
}
