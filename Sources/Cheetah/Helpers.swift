//
//  Helpers.swift
//  Cheetah
//
//  Created by Joannis Orlandos on 18/02/2017.
//
//

extension Optional where Wrapped == Value {
    /// Serializes the underlying value if available
    /// 
    /// Returns a serialized Null otherwise
    public func serialize() -> [UInt8] {
        return self?.serialize() ?? SpecialWords.null
    }
    
    /// If this optional contains a JSONArray it'll return the Value at the provided position only if it exists.
    ///
    /// Otherwise it will return nil
    ///
    /// This does not crash unlike Swift arrays
    public subscript(_ position: Int) -> Value? {
        guard let me = self as? JSONArray, me.count > position else {
            return nil
        }
        
        return me[position]
    }
    
    /// If this optional contains a JSONObject it'll return the Value at the provided key only if it exists.
    ///
    /// Otherwise it will return nil
    ///
    /// When setting, if the receiver is not already an object, it will be overwritten by a new object
    public subscript(_ key: String) -> Value? {
        get {
            return (self as? JSONObject)?[key]
        }
        set {
            var object = (self as? JSONObject) ?? [:]
            object[key] = newValue
            self = object
        }
    }
}

extension JSONObject {
    /// Helper initializer to initialize a JSONObject from a Value
    public init?(_ value: Value?) {
        if let me = value as? JSONObject {
            self = me
        } else {
            return nil
        }
    }
}

extension JSONArray {
    /// Helper initializer to initialize a JSONArray from a Value
    public init?(_ value: Value?) {
        if let me = value as? JSONArray {
            self = me
        } else {
            return nil
        }
    }
}

extension String {
    /// Helper initializer to initialize a String from a Value
    public init?(_ value: Value?) {
        switch value {
        case let me as String:
            self = me
        case let me as Int:
            self = me.description
        case let me as Bool:
            self = me ? "true" : "false"
        case let me as Double:
            self = me.description
        default:
            return nil
        }
    }
    
    /// Serializes the value if it exists, otherwise it'll serialize "null"
    public init(serializing value: Value?) {
        guard let me = String(bytes: value.serialize(), encoding: .utf8) else {
            self = "null"
            return
        }
        
        self = me
    }
}

extension Bool {
    /// Initializes this value if the received value is a boolean. Otherwise it'll inialize to nil
    public init?(_ value: Value?) {
        guard let me = value as? Bool else {
            return nil
        }
        
        self = me
    }
}

extension Int {
    /// Initializes this value if the received value is an integer
    public init?(_ value: Value?) {
        switch value {
        case let me as Int:
            self = me
        case let me as Double:
            self = Int(me)
        case let me as String:
            guard let int = Int(me) else {
                return nil
            }
            
            self = int
        default:
            return nil
        }
    }
}

extension Double {
    /// Initializes this value if the received value is a double
    public init?(_ value: Value?) {
        switch value {
        case let me as Int:
            self = Double(me)
        case let me as Double:
            self = me
        case let me as String:
            guard let double = Double(me) else {
                return nil
            }
            
            self = double
        default:
            return nil
        }
    }
}
