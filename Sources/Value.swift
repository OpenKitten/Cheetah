import KittenCore
import Foundation

/// A JSON Primitive type
public protocol Value : Convertible {
    func serialize() -> [UInt8]
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
        buffer.append(contentsOf: [UInt8](self.utf8))
        return buffer + [SpecialCharacters.stringQuotationMark]
    }
    
    /// Converts this String to JSON binary representation by escaping it
    func makeJSONBinary() -> [UInt8] {
        var buffer = [UInt8]()
        
        let lowercasedRadix16table: [UInt8] = [0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66]
        
        for char in self.unicodeScalars {
            switch char.value {
            case numericCast(SpecialCharacters.stringQuotationMark):
                buffer.append(contentsOf: "\"".utf8)
            case numericCast(SpecialCharacters.escape):
                buffer.append(contentsOf: "\\".utf8)
            case numericCast(SpecialCharacters.tab):
                buffer.append(contentsOf: "\t".utf8)
            case numericCast(SpecialCharacters.lineFeed):
                buffer.append(contentsOf: "\n".utf8)
            case numericCast(SpecialCharacters.carriageReturn):
                buffer.append(contentsOf: "\r".utf8)
            case numericCast(SpecialCharacters.tab):
                buffer.append(contentsOf: "\t".utf8)
            case 0x00...0x1F:
                buffer.append(contentsOf: "\\u".utf8)
                let str = String(char.value, radix: 16, uppercase: true)
                if str.characters.count == 1 {
                    buffer.append(contentsOf: "000\(str)".utf8)
                } else {
                    buffer.append(contentsOf: "00\(str)".utf8)
                }
            case 0x20...0xFF:
                let character = UInt8(char.value)
                buffer.append(character)
            case 0x100..<UInt32(UInt16.max):
                var character = UInt16(char.value)
                
                buffer.append(SpecialCharacters.escape)
                buffer.append(0x75)
                
                buffer.append(lowercasedRadix16table[Int(character / 4096)])
                
                character = character % 4096
                buffer.append(lowercasedRadix16table[Int(character / 256)])
                
                character = character % 256
                buffer.append(lowercasedRadix16table[Int(character / 16)])
                
                character = character % 16
                buffer.append(lowercasedRadix16table[Int(character)])
            default:
                func append(_ character: inout UInt16) {
                    buffer.append(SpecialCharacters.escape)
                    buffer.append(0x75)
                    
                    buffer.append(lowercasedRadix16table[Int(character / 4096)])
                    
                    character = character % 4096
                    buffer.append(lowercasedRadix16table[Int(character / 256)])
                    
                    character = character % 256
                    buffer.append(lowercasedRadix16table[Int(character / 16)])
                    
                    character = character % 16
                    buffer.append(lowercasedRadix16table[Int(character)])
                }
                
                let characterValue = char.value - UInt32(UInt16.max) - 1
                
                // Highest 10 + high surrogate
                var character0 = UInt16(characterValue >> 10) + 55_296
                // Highest lowest + low surrogate
                var character1 = UInt16((characterValue << 22) >> 22) + 56320
                
                append(&character0)
                append(&character1)
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

extension Null : Value {
    /// Serializes Null to a JSON String as binary
    public func serialize() -> [UInt8] {
        return SpecialWords.null
    }
    
    public func converted<ST>() -> ST? {
        return nil
    }
}
