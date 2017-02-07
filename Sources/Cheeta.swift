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
        var parser = JSON([UInt8](data.utf8), allowingComments: allowingComments)
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
        var parser = JSON([UInt8](data.utf8), allowingComments: allowingComments)
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
            default:
                Character(char).
            }
        }
        
        return buffer
    }
    
    public func escaped() -> [UInt8] {
        var buffer = [UInt8]()
        
        for char in self.unicodeScalars {
            switch char.value {
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
            case numericCast(SpecialCharacters.tab):
                buffer.append(contentsOf: "\\t".utf8)
            case 0...0x1F:
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
            default:
                continue
            }
        }
        
        return buffer
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
        return [UInt8]("\(self)".escaped())
    }
}

extension Double: JSONValue {
    public func serialize() -> [UInt8] {
        return [UInt8]("\(self)".escaped())
    }
}

public struct Null: JSONValue {
    public func serialize() -> [UInt8] {
        return SpecialWords.null
    }
}
