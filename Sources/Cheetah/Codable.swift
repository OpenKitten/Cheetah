//
//  Codable.swift
//  Cheetah
//
//  Created by Joannis Orlandos on 22/06/2017.
//

#if swift(>=3.2)

import Foundation

// MARK: Encoding

public class JSONEncoder {
    public init() {}
    
    public func encode(_ value: Encodable) throws -> JSONObject {
        let encoder = _JSONEncoder()
        try value.encode(to: encoder)
        
        return encoder.target.object
    }
    
    public func encodeArray(_ value: Encodable) throws -> JSONArray {
        let encoder = _JSONEncoder(target: .array(JSONArray()))
        try value.encode(to: encoder)
        
        return encoder.target.array
    }
    
    public func encode(value: Encodable) throws -> Value? {
        let encoder = _JSONEncoder(target: .primitive(get: { nil }, set: { _ in }))
        try value.encode(to: encoder)
        
        return encoder.target.value
    }
}

fileprivate protocol _JSONFakePrimitiveValue {}
extension Dictionary : _JSONFakePrimitiveValue {}
extension Array : _JSONFakePrimitiveValue {}

fileprivate class _JSONEncoder : Encoder, _JSONCodingPathContaining {
    enum Target {
        case object(JSONObject)
        case array(JSONArray)
        case primitive(get: () -> Value?, set: (Value?) -> ())
        
        var object: JSONObject {
            get {
                switch self {
                case .object(let obj): return obj
                case .array: return JSONObject()
                case .primitive(let get, _): return get() as? JSONObject ?? JSONObject()
                }
            }
            set {
                switch self {
                case .object: self = .object(newValue)
                case .array: self = .object([:])
                case .primitive(_, let set): set(newValue)
                }
            }
        }
        
        var array: JSONArray {
            get {
                switch self {
                case .object: return JSONArray()
                case .array(let arr): return arr
                case .primitive(let get, _): return get() as? JSONArray ?? JSONArray()
                }
            }
            set {
                switch self {
                case .object: self = .array([])
                case .array: self = .array(newValue)
                case .primitive(_, let set): set(newValue)
                }
            }
        }
        
        var value: Value? {
            get {
                switch self {
                case .object(let obj): return obj
                case .array(let arr): return arr
                case .primitive(let get, _): return get()
                }
            }
            set {
                switch self {
                case .object: self = .object(newValue as! JSONObject)
                case .array: self = .array(newValue as! JSONArray)
                case .primitive(_, let set): set(newValue)
                }
            }
        }
    }
    
    var codingPath: [CodingKey]
    
    var target: Target
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    func container<K>(keyedBy type: K.Type) -> KeyedEncodingContainer<K> {
        let container = _JSONKeyedEncodingContainer<K>(encoder: self)
        return KeyedEncodingContainer(container)
    }
    
    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return _JSONUnkeyedEncodingContainer(encoder: self)
    }
    
    func singleValueContainer() -> SingleValueEncodingContainer {
        return _JSONSingleValueEncodingContainer(encoder: self)
    }
    
    init(codingPath: [CodingKey] = [], target: Target = .object([:])) {
        self.codingPath = codingPath
        self.target = target
    }
    
    func convert(_ value: Bool) throws -> Value { return value }
    func convert(_ value: Int) throws -> Value { return value }
    func convert(_ value: Int8) throws -> Value { return Int(value) }
    func convert(_ value: Int16) throws -> Value { return Int(value) }
    func convert(_ value: Int32) throws -> Value { return Int(value) }
    func convert(_ value: Int64) throws -> Value { return Int(value) }
    func convert(_ value: UInt8) throws -> Value { return Int(value) }
    func convert(_ value: UInt16) throws -> Value { return Int(value) }
    func convert(_ value: UInt32) throws -> Value { return Int(value) }
    func convert(_ value: Float) throws -> Value { return Double(value) }
    func convert(_ value: Double) throws -> Value { return value }
    func convert(_ value: String) throws -> Value { return value }
    func convert(_ value: UInt) throws -> Value {
        guard value < Int.max else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: codingPath, debugDescription: "Value exceeds \(Int.max) which is the Int limit"))
        }
        
        return Int(value)
    }
    
    func convert(_ value: UInt64) throws -> Value {
        // BSON only supports 64 bit platforms where UInt64 is the same size as Int64
        return try convert(UInt(value))
    }
    
    func encode<T : Encodable>(_ value: T) throws -> Value? {
        if let primitive = value as? Value, !(primitive is _JSONFakePrimitiveValue) {
            return primitive
        } else {
            var primitive: Value? = nil
            let encoder = _JSONEncoder(target: .primitive(get: { primitive }, set: { primitive = $0 }))
            try value.encode(to: encoder)
            return primitive
        }
    }
}

extension JSONArray {
    fileprivate subscript(index: Int) -> Value? {
        get {
            guard self.count > index else {
                return nil
            }
            
            return self.storage[index]
        }
        set {
            if let newValue = newValue {
                if self.count > index {
                    self.append(newValue)
                } else {
                    self.storage[index] = newValue
                }
            } else if self.count <= index {
                self.storage.remove(at: index)
            }
        }
    }
}

fileprivate struct _JSONUnkeyedEncodingContainer : UnkeyedEncodingContainer {
    var count: Int {
        return encoder.target.array.count
    }
    
    mutating func encodeNil() throws {
        encoder.target.array.append(NSNull())
    }
    
    var encoder: _JSONEncoder
    var codingPath: [CodingKey] {
        get {
            return encoder.codingPath
        }
        set {
            encoder.codingPath = newValue
        }
    }
    
    init(encoder: _JSONEncoder) {
        self.encoder = encoder
    }
    
    private func nestedEncoder() -> _JSONEncoder {
        let index = self.encoder.target.array.count
        
        return _JSONEncoder(codingPath: codingPath, target: .primitive(get: {
            return self.encoder.target.array[index]
        }, set: { value in
            if let value = value {
                if self.encoder.target.array.count > index {
                    self.encoder.target.array[index] = value
                } else {
                    self.encoder.target.array.append(value)
                }
            }
        }))
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        let encoder = nestedEncoder()
        let container = _JSONKeyedEncodingContainer<NestedKey>(encoder: encoder)
        return KeyedEncodingContainer(container)
    }
    
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let encoder = nestedEncoder()
        return _JSONUnkeyedEncodingContainer(encoder: encoder)
    }
    
    func superEncoder() -> Encoder {
        // TODO: Check: is this OK?
        return nestedEncoder()
    }
    
    func encode(_ value: Bool) throws { try encoder.target.array.append(encoder.convert(value)) }
    func encode(_ value: Int) throws { try encoder.target.array.append(encoder.convert(value)) }
    func encode(_ value: Int8) throws { try encoder.target.array.append(encoder.convert(value)) }
    func encode(_ value: Int16) throws { try encoder.target.array.append(encoder.convert(value)) }
    func encode(_ value: Int32) throws { try encoder.target.array.append(encoder.convert(value)) }
    func encode(_ value: Int64) throws { try encoder.target.array.append(encoder.convert(value)) }
    func encode(_ value: UInt) throws { try encoder.target.array.append(encoder.convert(value)) }
    func encode(_ value: UInt8) throws { try encoder.target.array.append(encoder.convert(value)) }
    func encode(_ value: UInt16) throws { try encoder.target.array.append(encoder.convert(value)) }
    func encode(_ value: UInt32) throws { try encoder.target.array.append(encoder.convert(value)) }
    func encode(_ value: UInt64) throws { try encoder.target.array.append(encoder.convert(value)) }
    func encode(_ value: String) throws { try encoder.target.array.append(encoder.convert(value)) }
    func encode(_ value: Float) throws { try encoder.target.array.append(encoder.convert(value)) }
    func encode(_ value: Double) throws { try encoder.target.array.append(encoder.convert(value)) }
    func encode<T : Encodable>(_ value: T) throws { try encoder.target.array.append(unwrap(encoder.encode(value), codingPath: codingPath)) }
}

fileprivate protocol _JSONCodingPathContaining : class {
    var codingPath: [CodingKey] { get set }
}

fileprivate func unwrap<T>(_ value: T?, codingPath: [CodingKey]) throws -> T {
    guard let value = value else {
        throw DecodingError.valueNotFound(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Value of type \(T.self) was not found"))
    }
    
    return value
}

extension _JSONCodingPathContaining {
    // MARK: - Coding Path Operations
    /// Performs the given closure with the given key pushed onto the end of the current coding path.
    ///
    /// - parameter key: The key to push. May be nil for unkeyed containers.
    /// - parameter work: The work to perform with the key in the path.
    func with<T>(pushedKey key: CodingKey, _ work: () throws -> T) rethrows -> T {
        self.codingPath.append(key)
        let ret: T = try work()
        self.codingPath.removeLast()
        return ret
    }
    
    func with<T>(replacedPath path: [CodingKey], _ work: () throws -> T) rethrows -> T {
        let originalPath = self.codingPath
        self.codingPath = path
        let ret: T = try work()
        self.codingPath = originalPath
        return ret
    }
}

fileprivate class _JSONKeyedEncodingContainer<K: CodingKey> : KeyedEncodingContainerProtocol, _JSONCodingPathContaining {
    func encodeNil(forKey key: K) throws {
        
    }
    
    func encode<T>(_ value: T, forKey key: K) throws where T : Encodable {
        try with(pushedKey: key) {
            encoder.target.object[key.stringValue] = try encoder.encode(value)
        }
    }
    
    private func nestedEncoder(forKey key: CodingKey) -> _JSONEncoder {
        return self.encoder.with(pushedKey: key) {
            return _JSONEncoder(codingPath: self.encoder.codingPath, target: .primitive(get: { self.encoder.target.object[key.stringValue] }, set: { self.encoder.target.object[key.stringValue] = $0 }))
        }
    }
    
    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: K) -> KeyedEncodingContainer<NestedKey> {
        let encoder = nestedEncoder(forKey: key)
        return encoder.container(keyedBy: keyType)
    }
    
    func nestedUnkeyedContainer(forKey key: K) -> UnkeyedEncodingContainer {
        let encoder = nestedEncoder(forKey: key)
        return encoder.unkeyedContainer()
    }
    
    func superEncoder() -> Encoder {
        return nestedEncoder(forKey: _JSONSuperKey.super)
    }
    
    func superEncoder(forKey key: K) -> Encoder {
        return nestedEncoder(forKey: key)
    }
    
    typealias Key = K
    
    let encoder: _JSONEncoder
    var codingPath: [CodingKey]
    
    init(encoder: _JSONEncoder) {
        self.encoder = encoder
        self.codingPath = encoder.codingPath
    }
}

fileprivate struct _JSONSingleValueEncodingContainer : SingleValueEncodingContainer {
    let encoder: _JSONEncoder
    let codingPath: [CodingKey]
    
    init(encoder: _JSONEncoder) {
        self.encoder = encoder
        self.codingPath = encoder.codingPath
    }
    
    func encodeNil() throws { encoder.target.value = nil }
    func encode(_ value: Bool) throws { try encoder.target.value = encoder.convert(value) }
    func encode(_ value: Int) throws { try encoder.target.value = encoder.convert(value) }
    func encode(_ value: Int8) throws { try encoder.target.value = encoder.convert(value) }
    func encode(_ value: Int16) throws { try encoder.target.value = encoder.convert(value) }
    func encode(_ value: Int32) throws { try encoder.target.value = encoder.convert(value) }
    func encode(_ value: Int64) throws { try encoder.target.value = encoder.convert(value) }
    func encode(_ value: UInt8) throws { try encoder.target.value = encoder.convert(value) }
    func encode(_ value: UInt16) throws { try encoder.target.value = encoder.convert(value) }
    func encode(_ value: UInt32) throws { try encoder.target.value = encoder.convert(value) }
    func encode(_ value: Float) throws { try encoder.target.value = encoder.convert(value) }
    func encode(_ value: Double) throws {
        try encoder.with(replacedPath: codingPath) {
            try encoder.target.value = encoder.convert(value)
        }
    }
    func encode(_ value: String) throws { try encoder.target.value = encoder.convert(value) }
    func encode(_ value: UInt) throws { try encoder.target.value = encoder.convert(value) }
    func encode(_ value: UInt64) throws { try encoder.target.value = encoder.convert(value) }
    func encode<T>(_ value: T) throws where T : Encodable { try encoder.target.value = encoder.encode(value) }
}

// MARK: Decoding

public class JSONDecoder {
    public init() {}
    
    public func decode<T : Decodable>(_ type: T.Type, from object: JSONObject) throws -> T {
        let decoder = _JSONDecoder(target: .object(object))
        return try T(from: decoder)
    }
    
    public func decode<T : Decodable>(_ type: T.Type, from array: JSONArray) throws -> T {
        let decoder = _JSONDecoder(target: .array(array))
        return try T(from: decoder)
    }
    
    public func decode<T : Decodable>(_ type: T.Type, from string: String) throws -> T {
        let decoder: _JSONDecoder
        
        if let object = try? JSONObject(from: string) {
            decoder = _JSONDecoder(target: .object(object))
        } else {
            let array = try JSONArray(from: string)
            decoder = _JSONDecoder(target: .array(array))
        }
        
        return try T(from: decoder)
    }
}

fileprivate class _JSONDecoder : Decoder, _JSONCodingPathContaining {
    enum Target {
        case object(JSONObject)
        case array(JSONArray)
        case primitive(get: () -> Value?)
        case storedPrimitive(Value?)
        
        var object: JSONObject {
            get {
                switch self {
                case .object(let obj): return obj
                case .array: return JSONObject()
                case .primitive(let get): return get() as? JSONObject ?? JSONObject()
                case .storedPrimitive(let val): return val as? JSONObject ?? JSONObject()
                }
            }
        }
        
        var array: JSONArray {
            get {
                switch self {
                case .object: return JSONArray()
                case .array(let arr): return arr
                case .primitive(let get): return get() as? JSONArray ?? JSONArray()
                case .storedPrimitive(let val): return val as? JSONArray ?? JSONArray()
                }
            }
        }
        
        var value: Value? {
            get {
                switch self {
                case .object(let obj): return obj
                case .array(let arr): return arr
                case .primitive(let get): return get()
                case .storedPrimitive(let val): return val
                }
            }
        }
    }
    let target: Target
    
    var codingPath: [CodingKey]
    
    var userInfo: [CodingUserInfoKey : Any] = [:]
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        let container = _JSONKeyedDecodingContainer<Key>(decoder: self, codingPath: self.codingPath)
        return KeyedDecodingContainer(container)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return _JSONUnkeyedDecodingContainer(decoder: self)
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return _JSONSingleValueDecodingContainer(codingPath: self.codingPath, decoder: self)
    }
    
    init(codingPath: [CodingKey] = [], target: Target) {
        self.target = target
        self.codingPath = codingPath
    }
    
    /// Performs the given closure with the given key pushed onto the end of the current coding path.
    ///
    /// - parameter key: The key to push. May be nil for unkeyed containers.
    /// - parameter work: The work to perform with the key in the path.
    func with<T>(pushedKey key: CodingKey, _ work: () throws -> T) rethrows -> T {
        self.codingPath.append(key)
        let ret: T = try work()
        self.codingPath.removeLast()
        return ret
    }
    
    // MARK: - Value conversion
    func unwrap<T : Value>(_ value: Value?) throws -> T {
        guard let primitiveValue = value, !(primitiveValue is NSNull) else {
            throw DecodingError.valueNotFound(Bool.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Value not found - expected value of type \(T.self), found null / nil"))
        }
        
        guard let tValue = primitiveValue as? T else {
            throw DecodingError.typeMismatch(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Type mismatch - expected value of type \(T.self), found \(type(of: primitiveValue))"))
        }
        
        return tValue
    }
    
    func unwrap(_ value: Value?) throws -> Int? {
        guard let primitiveValue = value, !(primitiveValue is NSNull) else {
            throw DecodingError.valueNotFound(Bool.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Value not found - expected value of type \(Int.self), found null / nil"))
        }
        
        switch primitiveValue {
        case let number as Int:
            return number
        case let number as Double:
            guard number > Double(Int.min) && number < Double(Int.max) else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(Int.self)"))
            }
            return Int(number) as Int
        default:
            throw DecodingError.typeMismatch(Int.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Type mismatch - expected value of type \(Int.self), found \(type(of: primitiveValue))"))
        }
    }
    
    func unwrap(_ value: Value?) throws -> Double {
        guard let primitiveValue = value, !(primitiveValue is NSNull) else {
            throw DecodingError.valueNotFound(Double.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Value not found - expected value of type \(Double.self), found null / nil"))
        }
        
        switch primitiveValue {
        case let number as Int:
            return Double(number)
        case let number as Double:
            return number
        default:
            throw DecodingError.typeMismatch(Double.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Type mismatch - expected value of type \(Double.self), found \(type(of: primitiveValue))"))
        }
    }
    
    func unwrap(_ value: Value?) throws -> Bool {
        guard let primitiveValue = value, !(primitiveValue is NSNull) else {
            throw DecodingError.valueNotFound(Bool.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Value not found - expected value of type \(Bool.self), found null / nil"))
        }
        
        guard let bool = primitiveValue as? Bool else {
            throw DecodingError.typeMismatch(Bool.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Type mismatch - expected value of type \(Bool.self), found \(type(of: primitiveValue))"))
        }
        
        return bool
    }
    
    func unwrap(_ value: Value?) throws -> Int8 {
        guard let number: Int = try unwrap(value) else {
            throw DecodingError.valueNotFound(Int8.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Value not found - expected value of type \(Int8.self), found null / nil"))
        }
        
        guard number > Int8.min && number < Int8.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(Int8.self)"))
        }
        return Int8(number)
    }
    
    func unwrap(_ value: Value?) throws -> Int16 {
        guard let number: Int = try unwrap(value) else {
            throw DecodingError.valueNotFound(Int16.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Value not found - expected value of type \(Int16.self), found null / nil"))
        }
        
        guard number > Int16.min && number < Int16.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(Int16.self)"))
        }
        return Int16(number)
    }
    
    func unwrap(_ value: Value?) throws -> Int32 {
        guard let number: Int = try unwrap(value) else {
            throw DecodingError.valueNotFound(Int32.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Value not found - expected value of type \(Int32.self), found null / nil"))
        }
        
        guard number > Int32.min && number < Int32.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(Int16.self)"))
        }
        return Int32(number)
    }
    
    func unwrap(_ value: Value?) throws -> Int64 {
        guard let number: Int = try unwrap(value) else {
            throw DecodingError.valueNotFound(Int64.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Value not found - expected value of type \(Int64.self), found null / nil"))
        }
        
        return Int64(number)
    }
    
    func unwrap(_ value: Value?) throws -> UInt8 {
        guard let number: Int = try unwrap(value) else {
            throw DecodingError.valueNotFound(UInt8.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Value not found - expected value of type \(UInt8.self), found null / nil"))
        }
        
        guard number > UInt8.min && number < UInt8.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(UInt8.self)"))
        }
        return UInt8(number)
    }
    
    func unwrap(_ value: Value?) throws -> UInt16 {
        guard let number: Int = try unwrap(value) else {
            throw DecodingError.valueNotFound(UInt16.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Value not found - expected value of type \(UInt16.self), found null / nil"))
        }
        
        guard number > UInt16.min && number < UInt16.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(UInt16.self)"))
        }
        return UInt16(number)
    }
    
    func unwrap(_ value: Value?) throws -> UInt32 {
        guard let number: Int = try unwrap(value) else {
            throw DecodingError.valueNotFound(UInt32.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Value not found - expected value of type \(UInt32.self), found null / nil"))
        }
        
        guard number > UInt32.min && number < UInt32.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(UInt32.self)"))
        }
        return UInt32(number)
    }
    
    func unwrap(_ value: Value?) throws -> Float {
        // TODO: Check losing precision like JSONEncoder
        guard let number: Double = try? unwrap(value) else {
            throw DecodingError.valueNotFound(Float.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Value not found - expected value of type \(Float.self), found null / nil"))
        }
        
        return Float(number)
    }
    
    func unwrap(_ value: Value?) throws -> UInt {
        guard let number: Int = try unwrap(value) else {
            throw DecodingError.valueNotFound(UInt.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Value not found - expected value of type \(UInt.self), found null / nil"))
        }
        
        guard number > UInt.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "BSON number <\(number)> does not fit in \(UInt.self)"))
        }
        return UInt(number)
    }
    
    func unwrap(_ value: Value?) throws -> UInt64 {
        return try unwrap(value)
    }
    
    func decode<T>(_ value: Value?) throws -> T where T : Decodable {
        guard let value = value, !(value is NSNull) else {
            throw DecodingError.valueNotFound(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Value not found - expected value of type \(T.self), found null / nil"))
        }
        
        if T.self == JSONObject.self {
            let document = try Cheetah.unwrap(unwrap(value), codingPath: codingPath) as JSONObject as! T
            return document
        } else if T.self == JSONArray.self {
            let document = try Cheetah.unwrap(unwrap(value), codingPath: codingPath) as JSONArray as! T
            return document
        }
        
        let decoder = _JSONDecoder(target: .storedPrimitive(value))
        return try T(from: decoder)
    }
}

fileprivate struct _JSONKeyedDecodingContainer<Key : CodingKey> : KeyedDecodingContainerProtocol {
    func decodeNil(forKey key: Key) throws -> Bool {
        return decoder.target.object[key.stringValue] == nil
    }
    
    let decoder: _JSONDecoder
    
    var codingPath: [CodingKey]
    
    var allKeys: [Key] {
        return decoder.target.object.keys.flatMap { Key(stringValue: $0) }
    }
    
    func contains(_ key: Key) -> Bool {
        print(key, ": ", decoder.target.object[key.stringValue] as Any)
        return decoder.target.object[key.stringValue] != nil
    }
    
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.object[key.stringValue])
        }
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.object[key.stringValue])
        }
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.object[key.stringValue])
        }
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.object[key.stringValue])
        }
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.object[key.stringValue])
        }
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.object[key.stringValue])
        }
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.object[key.stringValue])
        }
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.object[key.stringValue])
        }
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.object[key.stringValue])
        }
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.object[key.stringValue])
        }
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.object[key.stringValue])
        }
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.object[key.stringValue])
        }
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.object[key.stringValue])
        }
    }
    
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        return try decoder.with(pushedKey: key) {
            return try decoder.unwrap(decoder.target.object[key.stringValue])
        }
    }
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        return try decoder.with(pushedKey: key) {
            return try decoder.decode(decoder.target.object[key.stringValue])
        }
    }
    
    private func nestedDecoder(forKey key: CodingKey) -> _JSONDecoder {
        return decoder.with(pushedKey: key) {
            return _JSONDecoder(codingPath: self.decoder.codingPath, target: .primitive(get: { self.decoder.target.object[key.stringValue] }))
        }
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        return try nestedDecoder(forKey: key).container(keyedBy: type)
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        return try nestedDecoder(forKey: key).unkeyedContainer()
    }
    
    func superDecoder() throws -> Decoder {
        return nestedDecoder(forKey: _JSONSuperKey.super)
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        return nestedDecoder(forKey: key)
    }
}

fileprivate class _JSONUnkeyedDecodingContainer : UnkeyedDecodingContainer, _JSONCodingPathContaining {
    func assertNotAtEnd(_ type: Any.Type) throws {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Unkeyed decoding container is at end"))
        }
    }
    
    func decodeNil() throws -> Bool {
        try assertNotAtEnd(NSNull.self)
        if decoder.target.array[currentIndex] == nil {
            currentIndex += 1
            return true
        } else {
            return false
        }
    }
    
    let decoder: _JSONDecoder
    var codingPath: [CodingKey]
    
    init(decoder: _JSONDecoder) {
        self.decoder = decoder
        self.codingPath = decoder.codingPath
    }
    
    var count: Int? { return decoder.target.array.count }
    var currentIndex: Int = 0
    var isAtEnd: Bool {
        return currentIndex >= self.count!
    }
    
    func next() -> Value? {
        defer { currentIndex += 1 }
        return decoder.target.array[currentIndex]
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        return try decoder.unwrap(next())
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        return try decoder.unwrap(next())
    }
    
    func decode(_ type: Int8.Type) throws -> Int8 {
        return try decoder.unwrap(next())
    }
    
    func decode(_ type: Int16.Type) throws -> Int16 {
        return try decoder.unwrap(next())
    }
    
    func decode(_ type: Int32.Type) throws -> Int32 {
        return try decoder.unwrap(next())
    }
    
    func decode(_ type: Int64.Type) throws -> Int64 {
        return try decoder.unwrap(next())
    }
    
    func decode(_ type: UInt.Type) throws -> UInt {
        return try decoder.unwrap(next())
    }
    
    func decode(_ type: UInt8.Type) throws -> UInt8 {
        return try decoder.unwrap(next())
    }
    
    func decode(_ type: UInt16.Type) throws -> UInt16 {
        return try decoder.unwrap(next())
    }
    
    func decode(_ type: UInt32.Type) throws -> UInt32 {
        return try decoder.unwrap(next())
    }
    
    func decode(_ type: UInt64.Type) throws -> UInt64 {
        return try decoder.unwrap(next())
    }
    
    func decode(_ type: Float.Type) throws -> Float {
        return try decoder.unwrap(next())
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        return try decoder.unwrap(next())
    }
    
    func decode(_ type: String.Type) throws -> String {
        return try decoder.unwrap(next())
    }
    
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        return try decoder.decode(next())
    }
    
    func nestedDecoder() throws -> _JSONDecoder {
        return try decoder.with(pushedKey: _JSONUnkeyedIndexKey(index: self.currentIndex)) {
            guard !isAtEnd else {
                throw DecodingError.valueNotFound(Decoder.self, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Cannot get nested decoder -- unkeyed container is at end."))
            }
            
            let value = next()
            return _JSONDecoder(target: .storedPrimitive(value))
        }
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        return try nestedDecoder().container(keyedBy: type)
    }
    
    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        return try nestedDecoder().unkeyedContainer()
    }
    
    func superDecoder() throws -> Decoder {
        return try nestedDecoder()
    }
    
}

fileprivate struct _JSONSingleValueDecodingContainer : SingleValueDecodingContainer {
    var codingPath: [CodingKey]
    let decoder: _JSONDecoder
    
    private func unwrap<T>(_ value: T?) throws -> T {
        return try Cheetah.unwrap(value, codingPath: decoder.codingPath)
    }
    
    func decodeNil() -> Bool { return decoder.target.value == nil }
    func decode(_ type: Bool.Type) throws -> Bool { return try unwrap(decoder.unwrap(decoder.target.value)) }
    func decode(_ type: Int.Type) throws -> Int { return try unwrap(decoder.unwrap(decoder.target.value)) }
    func decode(_ type: Int8.Type) throws -> Int8 { return try unwrap(decoder.unwrap(decoder.target.value)) }
    func decode(_ type: Int16.Type) throws -> Int16 { return try unwrap(decoder.unwrap(decoder.target.value)) }
    func decode(_ type: Int32.Type) throws -> Int32 { return try unwrap(decoder.unwrap(decoder.target.value)) }
    func decode(_ type: Int64.Type) throws -> Int64 { return try unwrap(decoder.unwrap(decoder.target.value)) }
    func decode(_ type: UInt.Type) throws -> UInt { return try unwrap(decoder.unwrap(decoder.target.value)) }
    func decode(_ type: UInt8.Type) throws -> UInt8 { return try unwrap(decoder.unwrap(decoder.target.value)) }
    func decode(_ type: UInt16.Type) throws -> UInt16 { return try unwrap(decoder.unwrap(decoder.target.value)) }
    func decode(_ type: UInt32.Type) throws -> UInt32 { return try unwrap(decoder.unwrap(decoder.target.value)) }
    func decode(_ type: UInt64.Type) throws -> UInt64 { return try unwrap(decoder.unwrap(decoder.target.value)) }
    func decode(_ type: Float.Type) throws -> Float { return try unwrap(decoder.unwrap(decoder.target.value)) }
    func decode(_ type: Double.Type) throws -> Double { return try unwrap(decoder.unwrap(decoder.target.value)) }
    func decode(_ type: String.Type) throws -> String { return try unwrap(decoder.unwrap(decoder.target.value)) }
    func decode<T>(_ type: T.Type) throws -> T where T : Decodable { return try unwrap(decoder.decode(decoder.target.value)) }
    
}

fileprivate enum _JSONSuperKey : String, CodingKey {
    case `super`
}

fileprivate struct _JSONUnkeyedIndexKey : CodingKey {
    var index: Int
    init(index: Int) {
        self.index = index
    }
    
    var intValue: Int? {
        return index
    }
    
    var stringValue: String {
        return String(describing: index)
    }
    
    init?(intValue: Int) {
        self.index = intValue
    }
    
    init?(stringValue: String) {
        return nil
    }
}

#endif
