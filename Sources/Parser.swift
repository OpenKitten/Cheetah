import Foundation
import KittenCore

internal enum EscapableCharacters: Character {
    case quote = "\""
//    case apostrophe = "'"
    case slash = "/"
    case backslash = "\\"
    //    case b = "\b"
    //    case b = "\f"
    case n = "\n"
    case r = "\r"
    case t = "\t"
}

/// Special key-words in JSON
internal enum SpecialWords {
    static let null: [UInt8] = [0x6e, 0x75, 0x6c, 0x6c]
    static let `true`: [UInt8] = [0x74, 0x72, 0x75, 0x65]
    static let `false`: [UInt8] = [0x66, 0x61, 0x6c, 0x73, 0x65]
}

/// Special characters in JSON that need special treatment (in some scenarios)
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

/// The JSON context
public struct JSON {
    /// The data that is being parsed
    let data: [UInt8]
    
    /// The position that remembers our current position in parsing
    var position: Int = 0
    
    /// Initializes this JSON context
    internal init<S : Sequence>(_ data: S, allowingComments: Bool) where S.Iterator.Element == UInt8 {
        self.data = Array(data)
    }
    
    /// Parses an escaped unicode character (as hexadecimal) at the current position
    ///
    /// Requires the position to be after the `\u`
    mutating func parseUnicode() throws -> UnicodeScalar {
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
        
        try require(4)
        var characters = [UInt16]()
        
        while true {
            let character = try makeInteger(from: Array(data[position..<position + 4]))
            
            position += 4
            
            characters.append(character)
            
            if characters.count > 1 {
                guard UTF16.isTrailSurrogate(character) else {
                    throw JSONError.invalidUnicodeCharacter
                }
                
                var utfParser = UTF16()
                var iterator = characters.makeIterator()
                switch utfParser.decode(&iterator) {
                case .scalarValue(let char):
                    return char
                case .emptyInput, .error:
                    throw JSONError.invalidUnicodeCharacter
                }
                
            } else if !UTF16.isLeadSurrogate(character) {
                guard let scalar = UnicodeScalar(character) else {
                    throw JSONError.invalidUnicodeCharacter
                }
                
                return scalar
            }
            
            guard remaining(2) && data[position] == SpecialCharacters.escape && data[position + 1] == 0x75 else {
                throw JSONError.invalidUnicodeCharacter
            }
            
            position += 2
        }
    }

    /// Parses a String at the current position
    mutating func parseString() throws -> String {
        try skipWhitespace()
        
        try require(1)
        
        guard data[position] == SpecialCharacters.stringQuotationMark else {
            throw JSONError.unexpectedToken(want: SpecialCharacters.stringQuotationMark)
        }
        
        position += 1
        
        var characters = [UInt8]()
        
        loop: while position < data.count {
            if data[position] == SpecialCharacters.escape {
                try require(1)
                
                // The `\`
                position += 1
                
                switch data[position] { // u
                // `u` for unicode
                case 0x75:
                    position += 1
                    let unicodeScalar = try parseUnicode()
                    characters.append(contentsOf: String(unicodeScalar).utf8)
                case SpecialCharacters.stringQuotationMark:
                    characters.append(SpecialCharacters.stringQuotationMark)
                    position += 1
                case SpecialCharacters.escape:
                    characters.append(SpecialCharacters.escape)
                    position += 1
                case 0x2f: // `/`
                    characters.append(SpecialCharacters.slash)
                    position += 1
                case 0x62: // `b`
                    throw JSONError.unsupported
                case 0x66: // `f`
                    throw JSONError.unsupported
                case 0x6e: // `n`
                    characters.append(SpecialCharacters.lineFeed)
                    position += 1
                case 0x72: // `r`
                    characters.append(SpecialCharacters.carriageReturn)
                    position += 1
                case 0x74: // `t`
                    characters.append(SpecialCharacters.tab)
                    position += 1
                default:
                    throw JSONError.invalidEscapedCharacter
                }
                // If this is the string end, but not escaped unless the escape is escaped
            } else if data[position] == SpecialCharacters.stringQuotationMark {
                position += 1
                
                try skipWhitespace()
                
                guard let string = String(bytes: characters, encoding: .utf8) else {
                    throw JSONError.invalidString
                }
                
                return string
            } else {
                characters.append(data[position])
                position += 1
            }
        }
        
        throw JSONError.unexpectedToken(want: SpecialCharacters.stringQuotationMark)
    }
    
    /// Parses a number (int or double, with or without exp) at this position
    mutating func parseNumber() throws -> Value {
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
    
    /// Parses any value at the current position
    mutating func parseValue() throws -> Value {
        try skipWhitespace()
        
        try require(1)
        
        defer {
            _ = try? skipWhitespace()
        }
        
        switch data[position] {
        case SpecialCharacters.stringQuotationMark:
            return try parseString()
        case SpecialCharacters.objectOpen:
            return try parse() as JSONObject
        case SpecialCharacters.arrayOpen:
            return try parse() as JSONArray
        case 0x30...0x39, SpecialCharacters.minus:
            return try parseNumber()
        case 0x6e: // `n`
            try require(4)
            guard [UInt8](data[position..<position + 4]) == SpecialWords.null else {
                throw JSONError.unknownValue
            }
            
            position += 4
            
            return Null()
        case 0x74: // `t`
            try require(4)
            guard [UInt8](data[position..<position + 4]) == SpecialWords.true else {
                throw JSONError.unknownValue
            }
            
            position += 4
            
            return true
        case 0x66: // `f`
            try require(5)
            guard [UInt8](data[position..<position + 5]) == SpecialWords.false else {
                throw JSONError.unknownValue
            }
            
            position += 5
            
            return false
        default:
            throw JSONError.unknownValue
        }
    }
    
    /// Parses an Array's comma separated values
    mutating func parseValues() throws -> [Value] {
        try skipWhitespace()
        
        if remaining(1), data[position] == SpecialCharacters.arrayClose {
            return []
        }
        
        var storage = [Value]()
        
        storage.append(try parseValue())
        
        while remaining(1), data[position] == SpecialCharacters.comma {
            position += 1
            storage.append(try parseValue())
        }
        
        return storage
    }
    
    /// Parses an Object's comma separated key-value pairs (pairs split by colon)
    mutating func parseKeyValues() throws -> [String: Value] {
        try skipWhitespace()
        
        if remaining(1), data[position] == SpecialCharacters.objectClose {
            return [:]
        }
        
        var storage = [String: Value]()
        
        func parseKeyValue() throws {
            try skipWhitespace()
            let key = try parseString()
            try skipWhitespace()
            
            try require(1)
            
            guard data[position] == SpecialCharacters.colon else {
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
    
    /// Skips whitespace including tab, linefeeds and carriage returns
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
                    try require(2)
                    
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
    
    /// Counts the remaining characters in the buffer
    func remaining() -> Int {
        return data.count - position
    }
    
    /// Throws if the required amount of data is not available
    func require(_ amount: Int) throws {
        guard remaining(amount) else {
            throw JSONError.unexpectedEndOfData
        }
    }
    
    /// Returns whether the requested amount of bytes is available
    func remaining(_ amount: Int) -> Bool {
        return remaining() > amount - 1
    }
    
    /// Parses an Array at this location
    mutating func parse(rootLevel: Bool = false) throws -> JSONArray {
        guard data.count >= 2 else {
            throw JSONError.invalidObject
        }
        
        try skipWhitespace()
        
        try require(1)
        
        guard data[position] == SpecialCharacters.arrayOpen else {
            throw JSONError.missingStartTag
        }
        
        position += 1
        
        try skipWhitespace()
        
        let storage = try parseValues()
        
        try skipWhitespace()
        
        try require(1)
        
        guard data[position] == SpecialCharacters.arrayClose else {
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
    
    /// Parses an object at this location
    mutating func parse(rootLevel: Bool = false) throws -> JSONObject {
        guard data.count >= 2 else {
            throw JSONError.invalidObject
        }
        
        try skipWhitespace()
        
        try require(1)
        
        guard data[position] == SpecialCharacters.objectOpen else {
            throw JSONError.missingStartTag
        }
        
        position += 1
        
        try skipWhitespace()
        
        let storage = try parseKeyValues()
        
        try require(1)
        
        guard data[position] == SpecialCharacters.objectClose else {
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
    
    /// Parses any value given a String
    public static func parse(from data: String, allowingComments: Bool = true) throws -> Value {
        return try parse(from: data.utf8)
    }
    
    /// Parses any value given a String bytes buffer
    public static func parse<S : Sequence>(from data: S, allowingComments: Bool = true) throws -> Value where S.Iterator.Element == UInt8 {
        var parser = JSON(data, allowingComments: allowingComments)
        try parser.skipWhitespace()
        
        guard parser.remaining(1) else {
            throw JSONError.unknownValue
        }
        
        let result: Value
        
        switch parser.data[parser.position] {
        case SpecialCharacters.stringQuotationMark:
            result = try parser.parseString()
        case SpecialCharacters.objectOpen:
            result = try parser.parse() as JSONObject
        case SpecialCharacters.arrayOpen:
            result = try parser.parse() as JSONArray
        case 0x30...0x39, SpecialCharacters.minus:
            result = try parser.parseNumber()
        case 0x6e: // `n`
            guard parser.remaining(4), [UInt8](parser.data[parser.position..<parser.position + 4]) == SpecialWords.null else {
                throw JSONError.unknownValue
            }
            
            parser.position += 4
            
            result = Null()
        case 0x74: // `t`
            guard parser.remaining(4), [UInt8](parser.data[parser.position..<parser.position + 4]) == SpecialWords.true else {
                throw JSONError.unknownValue
            }
            
            parser.position += 4
            
            result = true
        case 0x66: // `f`
            guard parser.remaining(5), [UInt8](parser.data[parser.position..<parser.position + 5]) == SpecialWords.false else {
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
