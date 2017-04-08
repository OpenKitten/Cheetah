//
//  Array.swift
//  Cheetah
//
//  Created by Joannis Orlandos on 18/02/2017.
//
//
import KittenCore

/// A JSON Array
public struct JSONArray: Value, InitializableSequence, ExpressibleByArrayLiteral, Equatable {
    /// Converts a sequence to a JSONArray
    public init<S>(sequence: S) where S : Sequence, S.Iterator.Element == JSONArray.SupportedValue {
        self.storage = Array(sequence)
    }

    /// This supports Cheetah.Value types
    public typealias SupportedValue = Value

    /// The Swift array representation
    internal var storage: [Value]
    
    /// The amount of values in this array
    public var count: Int {
        return storage.count
    }
    
    /// Returns the value at the given position in this array of values
    public subscript(position: Int) -> Value {
        get {
            return self.storage[position]
        }
        set {
            self.storage[position] = newValue
        }
    }
    
    /// Compares two array to see if both the values and the order are equal
    public static func ==(lhs: JSONArray, rhs: JSONArray) -> Bool {
        for (key, value) in lhs.enumerated() {
            guard key < rhs.count else {
                return false
            }
            
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
    
    /// Initlializes this JSON array with a Swift array
    public init(_ storage: [Value]) {
        self.storage = storage
    }
    
    /// Initlializes this JSON array with a Swift array literal
    public init(arrayLiteral elements: Value...) {
        self.storage = elements
    }
    
    /// Initializes this JSON Array with a JSON String containing this array in JSON format
    public init(from data: String, allowingComments: Bool = true) throws {
        var parser = JSON(data.utf8, allowingComments: allowingComments)
        self = try parser.parse(rootLevel: true)
    }
    
    /// Initializes this JSON Array with a JSON String as byte array containing this array in JSON format
    public init(from data: [UInt8], allowingComments: Bool = true) throws {
        var parser = JSON(data, allowingComments: allowingComments)
        self = try parser.parse(rootLevel: true)
    }
    
    /// Serializes this Array to a JSON Array String as bytes
    public func serialize() -> [UInt8] {
        var serializedData: [UInt8] = [SpecialCharacters.arrayOpen]
        
        for (position, value) in storage.enumerated() {
            if position > 0 {
                serializedData.append(SpecialCharacters.comma)
            }
            
            serializedData.append(contentsOf: value.serialize())
        }
        
        return serializedData + [SpecialCharacters.arrayClose]
    }
    
    /// Makes a JSONArray iterable
    public func makeIterator() -> IndexingIterator<[Value]> {
        return storage.makeIterator()
    }
}
