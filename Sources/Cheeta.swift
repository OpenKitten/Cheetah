import Foundation

public protocol JSONValue {
    func serialize() -> [UInt8]
}

public enum JSONError : Error {
    case missingStartTag
    case missingEndTag
    case invalidObject
    case invalidArray
    case invalidInteger
    case invalidEscapedCharacter
    case invalidNumber
    case invalidUnicodeCharacter
    case unexpectedToken(want: UInt8)
    case unexpectedTrailingTokens
    case unexpectedEndOfData
    case unsupported
    case unclosedComment
    case unknownValue
}

extension UInt8 {
    var character: Character {
        return Character(UnicodeScalar(self))
    }
}

public struct JSONObject : JSONValue, Sequence, ExpressibleByDictionaryLiteral, Equatable {
    internal var storage = [String: JSONValue]()
    
    public subscript(_ key: String) -> JSONValue? {
        get {
            return storage[key]
        }
        set {
            storage[key] = newValue
        }
    }
    
    public var keys: [String] {
        return Array(storage.keys)
    }
    
    public var values: [JSONValue] {
        return Array(storage.values)
    }
    
    public var dictionaryValue: [String: JSONValue] {
        return storage
    }
    
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
    
    public init(dictionaryLiteral elements: (String, JSONValue)...) {
        for (key, value) in elements {
            self.storage[key] = value
        }
    }
    
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
    
    public init(from data: String, allowingComments: Bool = true) throws {
        var parser = JSON(data.makeJSONBinary(), allowingComments: allowingComments)
        self = try parser.parse(rootLevel: true)
    }
    
    public init(_ dictionary: [String: JSONValue]) {
        self.storage = dictionary
    }

    public init(from data: [UInt8], allowingComments: Bool = true) throws {
        var parser = JSON(data, allowingComments: allowingComments)
        self = try parser.parse(rootLevel: true)
    }
    
    public func makeIterator() -> DictionaryIterator<String, JSONValue> {
        return storage.makeIterator()
    }
}

public struct JSONArray: JSONValue, Sequence, ExpressibleByArrayLiteral, Equatable {
    public var count: Int {
        return storage.count
    }

    public subscript(position: Int) -> JSONValue {
        get {
            return self.storage[position]
        }
        set {
            self.storage[position] = newValue
        }
    }
    
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
    
    public private(set) var storage: [JSONValue]
    
    public init(_ storage: [JSONValue]) {
        self.storage = storage
    }
    
    public init(arrayLiteral elements: JSONValue...) {
        self.storage = elements
    }
    
    public init(from data: [UInt8], allowingComments: Bool = true) throws {
        var parser = JSON(data, allowingComments: allowingComments)
        self = try parser.parse(rootLevel: true)
    }
    
    public init(from data: String, allowingComments: Bool = true) throws {
        var parser = JSON(data.makeJSONBinary(), allowingComments: allowingComments)
        self = try parser.parse(rootLevel: true)
    }
    
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
    
    public func makeIterator() -> IndexingIterator<[JSONValue]> {
        return storage.makeIterator()
    }
}

extension String: JSONValue {
    public func serialize() -> [UInt8] {
        var buffer: [UInt8] = [SpecialCharacters.stringQuotationMark]
        buffer.append(contentsOf: [UInt8](self.utf8))
        return buffer + [SpecialCharacters.stringQuotationMark]
    }
    
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
    
//    public func escaped() -> [UInt8] {
//        var buffer = [UInt8]()
//        
//        let lowercasedRadix16table: [UInt8] = [0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66]
//        
//        for char in self.unicodeScalars {
//            switch char.value {
//            case numericCast(SpecialCharacters.stringQuotationMark):
//                buffer.append(contentsOf: "\\\"".utf8)
//            case numericCast(SpecialCharacters.escape):
//                buffer.append(contentsOf: "\\\\".utf8)
//            case numericCast(SpecialCharacters.tab):
//                buffer.append(contentsOf: "\\t".utf8)
//            case numericCast(SpecialCharacters.lineFeed):
//                buffer.append(contentsOf: "\\n".utf8)
//            case numericCast(SpecialCharacters.carriageReturn):
//                buffer.append(contentsOf: "\\r".utf8)
//            case numericCast(SpecialCharacters.tab):
//                buffer.append(contentsOf: "\\t".utf8)
//            case 0...0x1F:
//                buffer.append(contentsOf: "\\u".utf8)
//                let str = String(char.value, radix: 16, uppercase: true)
//                if str.characters.count == 1 {
//                    buffer.append(contentsOf: "000\(str)".utf8)
//                } else {
//                    buffer.append(contentsOf: "00\(str)".utf8)
//                }
//            case 0x20...0xFF:
//                let character = UInt8(char.value)
//                buffer.append(character)
//            default:
//                
//            }
//        }
//        
//        return buffer
//    }
}

extension UInt32 {
    internal func makeBytes() -> [UInt8] {
        let integer = self.littleEndian
        
        return [
            UInt8(integer & 0xFF),
            UInt8((integer >> 8) & 0xFF),
            UInt8((integer >> 16) & 0xFF),
            UInt8((integer >> 24) & 0xFF),
        ]
    }
}

extension UInt16 {
    internal func makeBytes() -> [UInt8] {
        let integer = self.littleEndian
        
        return [
            UInt8(integer & 0xFF),
            UInt8((integer >> 8) & 0xFF)
        ]
    }
}

extension Bool: JSONValue {
    public func serialize() -> [UInt8] {
        // return self ? "true" : "false"
        return self ? SpecialWords.true : SpecialWords.false
    }
}

extension Int: JSONValue {
    public func serialize() -> [UInt8] {
        return [UInt8]("\(self)".utf8)
    }
}

extension Double: JSONValue {
    public func serialize() -> [UInt8] {
        return [UInt8]("\(self)".utf8)
    }
}

public struct Null: JSONValue {
    public func serialize() -> [UInt8] {
        return SpecialWords.null
    }
}
