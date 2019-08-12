import Foundation

/// A JSON Primitive type
public protocol Value {
    /// Serializes this to binary
    func serialize() -> [UInt8]
}

extension Value {
    /// Serializes this value to a String
    public func serializedString() -> String {
        return String(bytes: self.serialize(), encoding: .utf8) ?? ""
    }
}

/// All possible errors
/// TODO: Discuss: Do we add docs? They're pretty obvious
public enum JSONError : Error {
    /// -
    case missingStartTag
    
    /// -
    case missingEndTag
    
    /// -
    case invalidObject
    
    /// -
    case invalidString
    
    /// -
    case invalidArray
    
    /// -
    case invalidInteger
    
    /// -
    case invalidEscapedCharacter
    
    /// -
    case invalidNumber
    
    /// -
    case invalidUnicodeCharacter
    
    /// -
    case unexpectedToken(want: UInt8)
    
    /// -
    case unexpectedTrailingTokens
    
    /// -
    case unexpectedEndOfData
    
    /// -
    case unsupported
    
    /// -
    case unclosedComment
    
    /// -
    case unknownValue
}

extension UInt8 {
    /// Creates a character from this Byte
    var character: Character {
        return Character(UnicodeScalar(self))
    }
}

extension String: Value {
    /// Serializes this String to a JSON String with quotes
    public func serialize() -> [UInt8] {
        var buffer: [UInt8] = [SpecialCharacters.stringQuotationMark]
        buffer.append(contentsOf: self.makeJSONBinary())
        return buffer + [SpecialCharacters.stringQuotationMark]
    }
    
    /// Converts this String to JSON binary representation by escaping it
    func makeJSONBinary() -> [UInt8] {
        var buffer = [UInt8]()
        
        for char in self.utf8 {
            switch char {
            case numericCast(SpecialCharacters.stringQuotationMark):
                buffer.append(contentsOf: "\\\"".utf8)
            case numericCast(SpecialCharacters.escape):
                buffer.append(contentsOf: "\\\\".utf8)
            case numericCast(SpecialCharacters.tab):
                buffer.append(contentsOf: "\\t".utf8)
            case numericCast(SpecialCharacters.lineFeed):
                buffer.append(contentsOf: "\\n".utf8)
            case numericCast(SpecialCharacters.carriageReturn):
                buffer.append(contentsOf: "\\r".utf8)
            case numericCast(0x08): // \b
                buffer.append(contentsOf: "\\b".utf8)
            case numericCast(0x0c): // \f
                buffer.append(contentsOf: "\\f".utf8)
            case 0x00...0x1F:
                buffer.append(contentsOf: "\\u".utf8)
                let str = String(char, radix: 16, uppercase: true)
                if str.count == 1 {
                    buffer.append(contentsOf: "000\(str)".utf8)
                } else {
                    buffer.append(contentsOf: "00\(str)".utf8)
                }
            default:
                buffer.append(char)
            }
        }
        
        return buffer
    }
}

extension Bool: Value {
    /// Serializes this boolean to a JSON String as binary
    public func serialize() -> [UInt8] {
        return self ? SpecialWords.true : SpecialWords.false
    }
}

extension Int: Value {
    /// Serializes this integer to a JSON String as binary
    public func serialize() -> [UInt8] {
        return [UInt8]("\(self)".utf8)
    }
}

extension Double: Value {
    /// Serializes this double to a JSON String as binary
    public func serialize() -> [UInt8] {
        return [UInt8]("\(self)".utf8)
    }
}

extension NSNull : Value {
    /// Serializes Null to a JSON String as binary
    public func serialize() -> [UInt8] {
        return SpecialWords.null
    }
    
    public func converted<ST>() -> ST? {
        return nil
    }
}

extension Dictionary : CheetahValue {
    public func serialize() -> [UInt8] {
        var dict = [String: CheetahValue]()
        
        for (key, value) in self {
            guard let key = key as? String, let value = value as? CheetahValue else {
                let error = "Only [String: Cheetah.Value] dictionaries are Cheetah.Value. Tried to initialize a JSONObject using [\(Element.self)]. This will crash on debug and print this message on release configurations."
                assertionFailure(error)
                print(error)
                continue
            }
            
            dict[key] = value
        }
        
        return JSONObject(dict).serialize()
    }
}

extension Array : CheetahValue {
    public func serialize() -> [UInt8] {
        let array = self.compactMap { value -> CheetahValue? in
            guard let value = value as? CheetahValue else {
                let error = "Only [Cheetah.Value] arrays are Cheetah.Value. Tried to initialize a JSONArray using [\(Element.self)]. This will crash on debug and print this message on release configurations."
                assertionFailure(error)
                print(error)
                return nil
            }
            
            return value
        }
        
        return JSONArray(array).serialize()
    }
}
