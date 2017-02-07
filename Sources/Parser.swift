import Foundation

internal enum EscapableCharacters: Character {
    case quote = "\""
    case apostrophe = "'"
    case slash = "/"
    case backslash = "\\"
    //    case b = "\b"
    //    case b = "\f"
    case n = "\n"
    case r = "\r"
    case t = "\t"
}

internal enum SpecialWords {
    static let null: [UInt8] = [0x6e, 0x75, 0x6c, 0x6c]
    static let `true`: [UInt8] = [0x74, 0x72, 0x75, 0x65]
    static let `false`: [UInt8] = [0x66, 0x61, 0x6c, 0x73, 0x65]
}

internal enum SpecialCharacters {
    static let tab: UInt8 = 0x09
    static let lineFeed: UInt8 = 0x0a
    static let carriageReturn: UInt8 = 0x0d
    static let space: UInt8 = 0x20
    
    static let objectOpen: UInt8 = 0x7b
    static let objectClose: UInt8 = 0x7d
    
    static let arrayOpen: UInt8 = 0x5b
    static let arrayClose: UInt8 = 0x5d
    
    static let stringQuotationMark: UInt8 = 0x22
    static let apostrophe: UInt8 = 0x27
    
    static let escape: UInt8 = 0x5c
    
    static let asterisk: UInt8 = 0x2a
    static let plus: UInt8 = 0x2b
    static let comma: UInt8 = 0x2c
    static let minus: UInt8 = 0x2d
    static let dot: UInt8 = 0x2e
    static let slash: UInt8 = 0x3f
    static let colon: UInt8 = 0x3a
}


public struct JSON {
    let data: [UInt8]
    var position: Int = 0
    
    internal init(_ data: [UInt8], allowingComments: Bool) {
        self.data = data
    }
    
    mutating func parseString() throws -> String {
        try skipWhitespace()
        
        guard remaining(1), data[position] == SpecialCharacters.stringQuotationMark || data[position] == SpecialCharacters.apostrophe else {
            throw JSONError.unexpectedToken(want: SpecialCharacters.stringQuotationMark)
        }
        
        let endCharacter = data[position]
        
        position += 1
        
        var characters = ""
        
        loop: while position < data.count {
            if data[position] == SpecialCharacters.escape {
                guard remaining(1) else {
                    throw JSONError.unexpectedEndOfData
                }
                
                // The `\`
                position += 1
                
                switch data[position] { // u
                // `u` for unicode
                case 0x75:
                    position += 1
                    
                    guard remaining(4) else {
                        throw JSONError.unexpectedEndOfData
                    }
                    
                    func makeInteger(from hex: [UInt8]) throws -> UTF16.CodeUnit {
                        var int: UInt16 = 0
                        
                        for (position, byte) in hex.reversed().enumerated() {
                            let lowercasedRadix16table: [UInt8] = [0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66]
                            
                            let uppercasedRadix16table: [UInt8] = [0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46]
                            
                            if let num = lowercasedRadix16table.index(of: byte) {
                                int += UInt16(num) * UInt16(pow(16, Double(position)))
                            } else if let num = uppercasedRadix16table.index(of: byte) {
                                int += UInt16(num) * UInt16(pow(16, Double(position)))
                            } else {
                                throw JSONError.invalidUnicodeCharacter
                            }
                        }
                        
                        return int
                    }
                    
                    func hasNextUnicode() -> Bool {
                        let unicode = remaining(6) && data[position] == SpecialCharacters.escape && data[position + 1] == 0x75
                        
                        if unicode {
                            position += 2
                        }
                        
                        return unicode
                    }
                    
                    var unicodeNumbers: [UTF16.CodeUnit] = []
                    
                    repeat {
                        unicodeNumbers.append(try makeInteger(from: Array(data[position..<position + 4])))
                        position += 4
                    } while hasNextUnicode()
                    
                    var utf = UTF16()
                    var iterator = unicodeNumbers.makeIterator()
                    
                    guard case .scalarValue(let character) = utf.decode(&iterator) else {
                        throw JSONError.invalidUnicodeCharacter
                    }
                    
                    characters.append(Character(character))
                case SpecialCharacters.stringQuotationMark:
                    characters.append(EscapableCharacters.quote.rawValue)
                    position += 1
                case SpecialCharacters.apostrophe:
                    characters.append(EscapableCharacters.apostrophe.rawValue)
                    position += 1
                case SpecialCharacters.escape:
                    characters.append(EscapableCharacters.backslash.rawValue)
                    position += 1
                case 0x2f: // `/`
                    characters.append(EscapableCharacters.slash.rawValue)
                    position += 1
                case 0x62: // `b`
                    throw JSONError.unsupported
                case 0x66: // `f`
                    throw JSONError.unsupported
                case 0x6e: // `n`
                    characters.append(EscapableCharacters.n.rawValue)
                    position += 1
                case 0x72: // `r`
                    characters.append(EscapableCharacters.r.rawValue)
                    position += 1
                case 0x74: // `t`
                    characters.append(EscapableCharacters.t.rawValue)
                    position += 1
                default:
                    throw JSONError.invalidEscapedCharacter
                }
                // If this is the string end, but not escaped unless the escape is escaped
            } else if data[position] == endCharacter {
                position += 1
                
                try skipWhitespace()
                
                return characters
            } else {
                defer { position += 1 }
                
                characters.append(Character(UnicodeScalar(data[position])))
            }
        }
        
        throw JSONError.unexpectedToken(want: endCharacter)
    }
    
    mutating func parseNumber() throws -> JSONValue {
        var negate = false
        
        func parseInteger(autoNegate: Bool = false) -> Int? {
            var int = (negate && autoNegate) ? "-" : ""
            
            // Loop over all digits
            while position < data.count && data[position] >= 0x30 && data[position] <= 0x39 {
                int.append(Character(UnicodeScalar(data[position])))
                position += 1
            }
            
            return Int(int)
        }
        
        func parseExp() -> Int? {
            if data[position] == SpecialCharacters.minus {
                position += 1
                
                if let number = parseInteger() {
                    return -number
                }
                
                return nil
            } else {
                if data[position] == SpecialCharacters.plus {
                    position += 1
                }
                
                return parseInteger()
            }
        }
        
        if remaining(1), data[position] == SpecialCharacters.minus {
            negate = true
            position += 1
        }
        
        guard let int = parseInteger(autoNegate: true) else {
            throw JSONError.invalidNumber
        }
        
        guard remaining(1) else {
            return int
        }
        
        if data[position] == SpecialCharacters.dot {
            position += 1
            
            guard let fracture = parseInteger() else {
                throw JSONError.invalidNumber
            }
            
            guard let parsedFracture = Double("0.\(fracture)") else {
                throw JSONError.invalidNumber
            }
            
            let baseNumber = Double(int) + (negate ? -parsedFracture : parsedFracture)
            
            if remaining(1), data[position] == 0x45 || data[position] == 0x65 {
                position += 1
                guard let exp = parseExp() else {
                    throw JSONError.invalidNumber
                }
                
                return baseNumber * pow(10, Double(exp))
            }
            
            return baseNumber
            
            // `E` or `e`
        } else if data[position] == 0x45 || data[position] == 0x65 {
            position += 1
            guard let exp = parseExp() else {
                throw JSONError.invalidNumber
            }
            
            return Double(int) * pow(10, Double(exp))
        } else {
            return int
        }
    }
    
    mutating func parseValue() throws -> JSONValue {
        try skipWhitespace()
        
        guard remaining(1) else {
            throw JSONError.unexpectedEndOfData
        }
        
        defer {
            _ = try? skipWhitespace()
        }
        
        switch data[position] {
        case SpecialCharacters.stringQuotationMark, SpecialCharacters.apostrophe:
            return try parseString()
        case SpecialCharacters.objectOpen:
            return try parse() as JSONObject
        case SpecialCharacters.arrayOpen:
            return try parse() as JSONArray
        case 0x30...0x39, SpecialCharacters.minus:
            return try parseNumber()
        case 0x6e: // `n`
            guard remaining(4), [UInt8](data[position..<position + 4]) == SpecialWords.null else {
                throw JSONError.unknownValue
            }
            
            position += 4
            
            return Null()
        case 0x74: // `t`
            guard remaining(4), [UInt8](data[position..<position + 4]) == SpecialWords.true else {
                throw JSONError.unknownValue
            }
            
            position += 4
            
            return true
        case 0x66: // `f`
            guard remaining(5), [UInt8](data[position..<position + 5]) == SpecialWords.false else {
                throw JSONError.unknownValue
            }
            
            position += 5
            
            return false
        default:
            throw JSONError.unknownValue
        }
    }
    
    mutating func parseValues() throws -> [JSONValue] {
        try skipWhitespace()
        
        if remaining(1), data[position] == SpecialCharacters.arrayClose {
            return []
        }
        
        var storage = [JSONValue]()
        
        storage.append(try parseValue())
        
        while remaining(1), data[position] == SpecialCharacters.comma {
            position += 1
            storage.append(try parseValue())
        }
        
        return storage
    }
    
    mutating func parseKeyValues() throws -> [String: JSONValue] {
        try skipWhitespace()
        
        if remaining(1), data[position] == SpecialCharacters.objectClose {
            return [:]
        }
        
        var storage = [String: JSONValue]()
        
        func parseKeyValue() throws {
            try skipWhitespace()
            let key = try parseString()
            try skipWhitespace()
            
            guard remaining(1), data[position] == SpecialCharacters.colon else {
                throw JSONError.invalidObject
            }
            
            position += 1
            
            try skipWhitespace()
            let value = try parseValue()
            try skipWhitespace()
            
            storage[key] = value
        }
        
        try parseKeyValue()
        
        while data[position] == SpecialCharacters.comma {
            position += 1
            try parseKeyValue()
        }
        
        return storage
    }
    
    mutating func skipWhitespace() throws {
        let whitespace: [UInt8] = [SpecialCharacters.tab, SpecialCharacters.space, SpecialCharacters.lineFeed, SpecialCharacters.carriageReturn]
        
        while position < data.count, whitespace.contains(data[position]) {
            position += 1
        }
        
        if remaining(2), data[position] == SpecialCharacters.slash {
            switch data[position + 1] {
            case SpecialCharacters.slash:
                while position < data.count {
                    if data[position] == 0x0a {
                        try skipWhitespace()
                        return
                    } else {
                        position += 1
                    }
                }
                
                throw JSONError.unexpectedTrailingTokens
            case SpecialCharacters.asterisk:
                var unclosed = 0
                while position < data.count {
                    guard remaining(2) else {
                        throw JSONError.unexpectedEndOfData
                    }
                    
                    if data[position] == SpecialCharacters.asterisk && data[position + 1] == SpecialCharacters.slash {
                        position += 2
                        unclosed -= 1
                        
                        if unclosed == 0 {
                            try skipWhitespace()
                            return
                        }
                    } else if data[position] == SpecialCharacters.slash && data[position + 1] == SpecialCharacters.asterisk {
                        position += 2
                        unclosed += 1
                    } else {
                        position += 1
                    }
                }
                
                throw JSONError.unclosedComment
            default:
                throw JSONError.unexpectedTrailingTokens
            }
        }
    }
    
    func remaining() -> Int {
        return data.count - position
    }
    
    func remaining(_ amount: Int) -> Bool {
        return remaining() > amount - 1
    }
    
    mutating func parse(rootLevel: Bool = false) throws -> JSONArray {
        guard data.count >= 2 else {
            throw JSONError.invalidObject
        }
        
        try skipWhitespace()
        
        guard remaining(1), data[position] == SpecialCharacters.arrayOpen else {
            throw JSONError.missingStartTag
        }
        
        position += 1
        
        try skipWhitespace()
        
        let storage = try parseValues()
        
        try skipWhitespace()
        
        guard remaining(1), data[position] == SpecialCharacters.arrayClose else {
            throw JSONError.missingEndTag
        }
        
        position += 1
        
        try skipWhitespace()
        
        if rootLevel {
            guard remaining() == 0 else {
                throw JSONError.unexpectedTrailingTokens
            }
        }
        
        return JSONArray(storage)
    }
    
    mutating func parse(rootLevel: Bool = false) throws -> JSONObject {
        guard data.count >= 2 else {
            throw JSONError.invalidObject
        }
        
        try skipWhitespace()
        
        guard remaining(1), data[position] == SpecialCharacters.objectOpen else {
            throw JSONError.missingStartTag
        }
        
        position += 1
        
        try skipWhitespace()
        
        let storage = try parseKeyValues()
        
        guard remaining(1), data[position] == SpecialCharacters.objectClose else {
            throw JSONError.missingEndTag
        }
        
        position += 1
        
        try skipWhitespace()
        
        if rootLevel {
            guard remaining() == 0 else {
                throw JSONError.unexpectedTrailingTokens
            }
        }
        
        return JSONObject(storage)
    }
    
    public static func parse(from data: String, allowingComments: Bool = true) throws -> JSONValue {
        return try parse(from: [UInt8](data.makeJSONBinary()))
    }
    
    public static func parse(from data: [UInt8], allowingComments: Bool = true) throws -> JSONValue {
        var parser = JSON(data, allowingComments: allowingComments)
        try parser.skipWhitespace()
        
        guard parser.remaining(1) else {
            throw JSONError.unknownValue
        }
        
        let result: JSONValue
        
        switch parser.data[parser.position] {
        case SpecialCharacters.stringQuotationMark, SpecialCharacters.apostrophe:
            result = try parser.parseString()
        case SpecialCharacters.objectOpen:
            result = try parser.parse() as JSONObject
        case SpecialCharacters.arrayOpen:
            result = try parser.parse() as JSONArray
        case 0x30...0x39, SpecialCharacters.minus:
            result = try parser.parseNumber()
        case 0x6e: // `n`
            guard parser.remaining(4), [UInt8](data[parser.position..<parser.position + 4]) == SpecialWords.null else {
                throw JSONError.unknownValue
            }
            
            parser.position += 4
            
            result = Null()
        case 0x74: // `t`
            guard parser.remaining(4), [UInt8](data[parser.position..<parser.position + 4]) == SpecialWords.true else {
                throw JSONError.unknownValue
            }
            
            parser.position += 4
            
            result = true
        case 0x66: // `f`
            guard parser.remaining(5), [UInt8](data[parser.position..<parser.position + 5]) == SpecialWords.false else {
                throw JSONError.unknownValue
            }
            
            parser.position += 5
            
            result = false
        default:
            throw JSONError.unknownValue
        }
        
        try parser.skipWhitespace()
        
        guard parser.remaining() == 0 else {
            throw JSONError.unexpectedTrailingTokens
        }
        
        return result
    }
}
