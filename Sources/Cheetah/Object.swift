//
//  Object.swift
//  Cheetah
//
//  Created by Joannis Orlandos on 18/02/2017.
//
//
import KittenCore

public enum JSONData : DataType {
    public typealias Object = JSONObject
    public typealias Sequence = JSONArray
    public typealias SupportedValue = Value
}

/// A JSON object/dictionary type
public struct JSONObject : Value, InitializableObject, ExpressibleByDictionaryLiteral, Equatable {
    public init<S>(sequence: S) where S : Sequence, S.Iterator.Element == SupportedValue {
        for (key, value) in sequence {
            storage[key] = value
        }
    }
    
    public typealias SupportedValue = (String, Value)
    
    public var dictionaryRepresentation: [String : Value] {
        return storage
    }
    
    /// The dictionary representation
    internal var storage = [String: Value]()
    
    /// Initializes this Object from a JSON String
    public init(from data: String, allowingComments: Bool = true) throws {
        var parser = JSON(data.utf8, allowingComments: allowingComments)
        self = try parser.parse(rootLevel: true)
    }
    
    /// Initializes this Object from a JSON String as byte array
    public init(from data: [UInt8], allowingComments: Bool = true) throws {
        var parser = JSON(data, allowingComments: allowingComments)
        self = try parser.parse(rootLevel: true)
    }
    
    /// Initializes this JSON Object with a Dictionary literal
    public init(dictionaryLiteral elements: (String, Value)...) {
        for (key, value) in elements {
            self.storage[key] = value
        }
    }
    
    /// Initializes this Object from a dictionary
    public init(_ dictionary: [String: Value]) {
        self.storage = dictionary
    }
    
    /// The amount of key-value pairs in this object
    public var count: Int {
        return storage.count
    }
    
    /// Accesses a value in the JSON Object
    public subscript(_ key: String) -> Value? {
        get {
            return storage[key]
        }
        set {
            storage[key] = newValue
        }
    }
    
    /// Returns all keys in this object
    public var keys: [String] {
        return Array(storage.keys)
    }
    
    /// Returns all values in this object
    public var values: [Value] {
        return Array(storage.values)
    }
    
    /// Returns the dictionary representation of this Object
    public var dictionaryValue: [String: Value] {
        return storage
    }
    
    /// Compares two Objects to see if all key-value pairs are equal
    public static func ==(lhs: JSONObject, rhs: JSONObject) -> Bool {
        for (key, value) in lhs {
            if let value = value as? String {
                guard let value2 = rhs[key] as? String else {
                    return false
                }
                
                guard value == value2 else {
                    return false
                }
                
            } else if let value = value as? Int {
                guard let value2 = rhs[key] as? Int else {
                    return false
                }
                
                guard value == value2 else {
                    return false
                }
                
            } else if let value = value as? Double {
                guard let value2 = rhs[key] as? Double else {
                    return false
                }
                
                guard value == value2 else {
                    return false
                }
                
            } else if let value = value as? JSONObject {
                guard let value2 = rhs[key] as? JSONObject else {
                    return false
                }
                
                guard value == value2 else {
                    return false
                }
                
            } else if let value = value as? JSONArray {
                guard let value2 = rhs[key] as? JSONArray else {
                    return false
                }
                
                guard value == value2 else {
                    return false
                }
                
            } else if value is Null {
                guard rhs[key] is Null else {
                    return false
                }
                
            } else if let value = value as? Bool {
                guard let value2 = rhs[key] as? Bool else {
                    return false
                }
                
                guard value == value2 else {
                    return false
                }
            }
        }
        
        return true
    }
    
    /// Serializes this JSON Object to a binary representation of the JSON text format
    public func serialize() -> [UInt8] {
        var serializedData: [UInt8] = [SpecialCharacters.objectOpen]
        
        for (position, pair) in storage.enumerated() {
            if position > 0 {
                serializedData.append(SpecialCharacters.comma)
            }
            
            serializedData.append(contentsOf: pair.0.serialize())
            serializedData.append(SpecialCharacters.colon)
            serializedData.append(contentsOf: pair.1.serialize())
        }
        
        return serializedData + [SpecialCharacters.objectClose]
    }
    
    /// Iterates over all key-value pairs
    public func makeIterator() -> DictionaryIterator<String, Value> {
        return storage.makeIterator()
    }
}
