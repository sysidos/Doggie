//
//  SDMarker.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2016 Susan Cheng. All rights reserved.
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

public struct SDMarker {
    
    fileprivate indirect enum Element {
        case string(String)
        case variable(String)
        case scope(String, [Element])
    }
    
    public enum Value {
        case string(String)
        case boolean(Bool)
        case integer(IntMax)
        case float(Double)
        case array([[String: Value]])
    }
    
    fileprivate let elements: [Element]
}

extension SDMarker {
    
    public init(template: String) {
        let characterSet = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ-_1234567890.:".characters)
        self.elements = SDMarker.parseScope(ArraySlice(template.characters), characterSet)
    }
    
    private static func parseScope(_ chars: ArraySlice<Character>, _ characterSet: Set<Character>) -> [Element] {
        var result: [Element] = []
        var chars = chars
        outer: while let index = chars.match(with: "{{".characters) {
            let head = chars.prefix(upTo: index + 2)
            let tail = chars.suffix(from: index + 2)
            if let token = parseToken(tail, characterSet) {
                switch token {
                case let .variable(name, end):
                    result.append(.string(String(head.dropLast(2))))
                    result.append(.variable(name))
                    chars = tail.suffix(from: end)
                    continue
                case let .scope(name, end):
                    var _tail = tail.dropFirst()
                    while let index2 = _tail.match(with: "{{#".characters) {
                        if let token = parseToken(_tail.suffix(from: index2 + 2), characterSet), case .scope(name, let end2) = token {
                            result.append(.string(String(head.dropLast(2))))
                            result.append(.scope(name, parseScope(tail.suffix(from: end).prefix(upTo: index2), characterSet)))
                            chars = _tail.suffix(from: end2)
                            continue outer
                        }
                        _tail = _tail.suffix(from: index2 + 3)
                    }
                }
            }
            result.append(.string(String(head)))
            chars = tail
        }
        result.append(.string(String(chars)))
        return result
    }
    
    private enum TokenType {
        case variable(String, Int)
        case scope(String, Int)
    }
    
    private static func parseToken(_ chars: ArraySlice<Character>, _ characterSet: Set<Character>) -> TokenType? {
        if let token = chars.first {
            switch token {
            case "%":
                if let end_token_index = chars.match(with: "%}}".characters), chars.startIndex + 1 != end_token_index {
                    let variable_name = String(chars.prefix(upTo: end_token_index).dropFirst()).trimmingCharacters(in: .whitespaces)
                    if variable_name.characters.all({ characterSet.contains($0) }) {
                        return .variable(variable_name, end_token_index + 3)
                    }
                }
            case "#":
                if let end_token_index = chars.match(with: "#}}".characters), chars.startIndex + 1 != end_token_index {
                    let scope_name = String(chars.prefix(upTo: end_token_index).dropFirst()).trimmingCharacters(in: .whitespaces)
                    if scope_name.characters.all({ characterSet.contains($0) }) {
                        return .scope(scope_name, end_token_index + 3)
                    }
                }
            default: break
            }
        }
        return nil
    }
}

extension SDMarker: ExpressibleByStringLiteral {
    
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public typealias UnicodeScalarLiteralType = StringLiteralType
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(template: value)
    }
    
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.init(template: value)
    }
    
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.init(template: value)
    }
}

extension SDMarker {
    
    public func render(_ values: [String: SDMarker.Value]) -> String {
        return self.elements.map { $0.render(stack: values) }.joined()
    }
}

extension SDMarker.Value {
    
    public init(_ val: Bool) {
        self = .boolean(val)
    }
    public init<S : SignedInteger>(_ val: S) {
        self = .integer(val.toIntMax())
    }
    public init(_ val: Float) {
        self = .float(Double(val))
    }
    public init(_ val: Double) {
        self = .float(val)
    }
    public init(_ val: String) {
        self = .string(val)
    }
    public init(_ val: [String: SDMarker.Value]) {
        self = .array([val])
    }
    public init<S : Sequence>(_ val: S) where S.Iterator.Element == [String: SDMarker.Value] {
        self = .array(Array(val))
    }
}

extension SDMarker.Value: ExpressibleByBooleanLiteral {
    
    public init(booleanLiteral value: BooleanLiteralType) {
        self.init(value)
    }
}

extension SDMarker.Value: ExpressibleByIntegerLiteral {
    
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }
}

extension SDMarker.Value: ExpressibleByFloatLiteral {
    
    public init(floatLiteral value: FloatLiteralType) {
        self.init(value)
    }
}

extension SDMarker.Value: ExpressibleByStringLiteral {
    
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
    public typealias UnicodeScalarLiteralType = StringLiteralType
    
    public init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }
    
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.init(value)
    }
    
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.init(value)
    }
}

extension SDMarker.Value: ExpressibleByArrayLiteral {
    
    public init(arrayLiteral elements: [String: SDMarker.Value] ...) {
        self.init(elements)
    }
}

extension SDMarker.Value: ExpressibleByDictionaryLiteral {
    
    public init(dictionaryLiteral elements: (String, SDMarker.Value) ...) {
        var dictionary: [String: SDMarker.Value] = [:]
        for (key, value) in elements {
            dictionary[key] = value
        }
        self.init(dictionary)
    }
}

extension SDMarker.Value : CustomStringConvertible {
    
    public var description: String {
        switch self {
        case let .string(string): return string
        case let .boolean(bool): return "\(bool)"
        case let .integer(integer): return "\(integer)"
        case let .float(float): return "\(float)"
        case let .array(array): return "\(array)"
        }
    }
}

extension SDMarker.Element {
    
    fileprivate func render(stack: [String: SDMarker.Value]) -> String {
        switch self {
        case let .string(str): return str
        case let .variable(name): return stack[name]?.description ?? ""
        case let .scope(name, elements):
            switch stack[name] ?? false {
            case let .boolean(bool):
                if bool {
                    return elements.lazy.map { $0.render(stack: stack) }.joined()
                }
            case let .integer(count):
                if count > 0 {
                    return (0..<count).lazy.map {
                        var stack = stack
                        stack[name] = .integer($0)
                        return elements.lazy.map { $0.render(stack: stack) }.joined()
                        }.joined()
                }
            case let .array(array):
                return array.lazy.map {
                    var stack = stack
                    stack[name] = .array([$0])
                    for (key, value) in $0 {
                        stack[key] = value
                    }
                    return elements.lazy.map { $0.render(stack: stack) }.joined()
                    }.joined()
            default: break
            }
            return ""
        }
    }
}
