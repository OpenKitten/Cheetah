
import XCTest
@testable import Cheetah

class ParsingTests: XCTestCase {
    
    func test_FailOnEmpty() {
        XCTAssertThrowsError(try JSON.parse(from: ""))
    }
    
    func test_CompletelyWrong() {
        XCTAssertThrowsError(try JSON.parse(from: "<XML>"))
    }
    
    func testExtraTokensThrow() {
        XCTAssertThrowsError(try JSON.parse(from: "{'hello':'world'} blah"))
    }
    
    
    // MARK: - Null
    
    func testNullParses() throws {
        XCTAssert(try JSON.parse(from: "null") is Null)
    }
    
    func testNullThrowsOnMismatch() {
        XCTAssertThrowsError(try JSON.parse(from: "nall"))
    }
    
    // MARK: - Bools
    
    func testTrueParses() throws {
        XCTAssertEqual(try JSON.parse(from: "true") as? Bool, true)
    }
    
    func testTrueThrowsOnMismatch() {
        XCTAssertThrowsError(try JSON.parse(from: "tRUe"))
    }
    
    func testFalseParses() {
        XCTAssertEqual(try JSON.parse(from: "false") as? Bool, false)
    }
    
    func testBoolean_False_Mismatch() {
        XCTAssertThrowsError(try JSON.parse(from: "fasle "))
    }
    
    
    // MARK: - Arrays
    
    func testArray_JustComma() throws {
        let array = try JSONArray(from: "[]")
        
        XCTAssertEqual(array.storage.count, 0)
        
        XCTAssertThrowsError(try JSONArray(from: "[,]"))
        XCTAssertThrowsError(try JSONArray(from: "[  , ]"))
    }
    
    func testArray_JustNull() throws {
        let array = try JSONArray(from: "[ null ]")
        
        XCTAssertEqual(array, [Null()])
    }
    
    func testArray_ZeroBegining() throws {
        let array = try JSONArray(from: "[ 0, 1 ]")
        
        XCTAssertEqual(array, [0, 1])
    }
    
    func testArray_ZeroBeginingWithWhitespace() throws {
        let array = try JSONArray(from: "[0            , 1] ")
        
        XCTAssertEqual(array, [0, 1])
    }
    
    func testArray_NullsBoolsNums_Normal_Minimal_RootParser() throws {
        XCTAssertEqual(try JSONArray(from: "[null,true,false,12,-10,-24.3,18.2e9]"),
            [Null(), true, false, 12, -10, -24.3, 18200000000.0])
    }
    
    func testArray_NullsBoolsNums_Normal_MuchWhitespace() throws {
        XCTAssertEqual(try JSONArray(from: " \t[\n  null ,true, \n-12.3 , false\r\n]\n  "),
            [Null(), true, -12.3, false])
    }
    
    func testArray_NullsAndBooleans_Bad_MissingEnd() {
        XCTAssertThrowsError(try JSON.parse(from: "[\n  null ,true, \nfalse\r\n\n  "))
    }
    
    func testArray_NullsAndBooleans_Bad_MissingComma() {
        XCTAssertThrowsError(try JSON.parse(from: "[\n  null true, \nfalse\r\n]\n  "))
    }
    
    func testArray_NullsAndBooleans_Bad_ExtraComma() {
        XCTAssertThrowsError(try JSON.parse(from: "[\n  null , , true, \nfalse\r\n]\n  "))
    }
    
    func testArray_NullsAndBooleans_Bad_TrailingComma() {
        XCTAssertThrowsError(try JSON.parse(from: "[\n  null ,true, \nfalse\r\n, ]\n  "))
    }
    
    
    // MARK: - Numbers
    
    func testNumber_Int_ZeroWithTrailingWhitespace() throws {
        XCTAssertEqual(try JSON.parse(from: "0  ") as? Int, 0)
    }
    
    func testNumber_Int_Zero() throws {
        XCTAssertEqual(try JSON.parse(from: "0") as? Int, 0)
    }
    
    func testNumber_Int_One() throws {
        XCTAssertEqual(try JSON.parse(from: "1") as? Int, 1)
    }
    
    func testNumber_Int_Basic() throws {
        XCTAssertEqual(try JSON.parse(from: "24") as? Int, 24)
    }
    
    func testNumber_IntMin() throws {
        XCTAssertEqual(try JSON.parse(from: Int.min.description) as? Int, Int.min)
    }
    
    func testNumber_IntMax() throws {
        XCTAssertEqual(try JSON.parse(from: Int.max.description) as? Int, Int.max)
    }
    
    func testNumber_Int_Negative() throws {
        XCTAssertEqual(try JSON.parse(from: "-32") as? Int, -32)
    }
    
    func testNumber_Int_Garbled() throws {
        XCTAssertThrowsError(try JSON.parse(from: "42-4"))
    }
    
//    func testNumber_Int_LeadingZero() throws {
//        XCTAssertThrowsError(try JSON.parse(from: "007"))
//    }
    
    func testNumber_Int_Overflow() throws {
        XCTAssertThrowsError(try JSON.parse(from: "9223372036854775808"))
        XCTAssertThrowsError(try JSON.parse(from: "18446744073709551616"))
        XCTAssertThrowsError(try JSON.parse(from: "18446744073709551616"))
    }
    
    
    func testNumber_Double_Overflow() throws {
        XCTAssertThrowsError(try JSON.parse(from: "18446744073709551616.0"))
        XCTAssertThrowsError(try JSON.parse(from: "1.18446744073709551616"))
        XCTAssertThrowsError(try JSON.parse(from: "1e18446744073709551616"))
        XCTAssertThrowsError(try JSON.parse(from: "184467440737095516106.0"))
        XCTAssertThrowsError(try JSON.parse(from: "1.184467440737095516106"))
        XCTAssertThrowsError(try JSON.parse(from: "1e184467440737095516106"))
    }
    
//    func testNumber_Dbl_LeadingZero() throws {
//        XCTAssertThrowsError(try JSON.parse(from: "006.123"))
//    }
    
    func testNumber_Dbl_Basic() throws {
        XCTAssertEqual(try JSON.parse(from: "46.57") as? Double, 46.57)
    }
    
    func testNumber_Dbl_ZeroSomething() throws {
        XCTAssertEqual(try JSON.parse(from: "0.98") as? Double, 0.98)
    }
    
    func testNumber_Dbl_MinusZeroSomething() throws {
        XCTAssertEqual(try JSON.parse(from: "-0.98") as? Double, -0.98)
    }
    
    func testNumber_Dbl_ThrowsOnMinus() {
        XCTAssertThrowsError(try JSON.parse(from: "-"))
    }
    
    func testNumber_Dbl_MinusDecimal() {
        XCTAssertThrowsError(try JSON.parse(from: "-.1"))
    }
    
    func testNumber_Dbl_Incomplete() {
        XCTAssertThrowsError(try JSON.parse(from: "24."))
    }
    
    func testNumber_Dbl_Negative() throws {
        XCTAssertEqual(try JSON.parse(from: "-24.34") as? Double, -24.34)
    }
    
    func testNumber_Dbl_Negative_WrongChar() {
        XCTAssertThrowsError(try JSON.parse(from: "-243a4"))
    }
    
    func testNumber_Dbl_Negative_TwoDecimalPoints() {
        XCTAssertThrowsError(try JSON.parse(from: "--24.3.4"))
    }
    
    func testNumber_Dbl_Negative_TwoMinuses() {
        XCTAssertThrowsError(try JSON.parse(from: "--24.34"))
    }
    
    // http://seriot.ch/parsing_json.html
    func testNumber_Double_ZeroExpOne() throws {
        XCTAssertEqual(try JSON.parse(from: "0e1") as? Double, 0.0)
    }
    
    func testNumber_Double_Exp_Normal() throws {
        XCTAssertEqual(try JSON.parse(from: "-24.3245e2") as? Double, -2432.45)
    }
    
    func testNumber_Double_Exp_Positive() throws {
        XCTAssertEqual(try JSON.parse(from: "-24.3245e+2") as? Double, -2432.45)
    }
    
    // TODO (vdka): floating point accuracy
    // Potential to fix through using Darwin.C.pow but, isn't that a dependency?
    // Maybe reimplement C's gross lookup table pow method
    // http://opensource.apple.com/source/Libm/Libm-2026/Source/Intel/expf_logf_powf.c
    // http://opensource.apple.com/source/Libm/Libm-315/Source/ARM/powf.c
    // May be hard to do this fast and correct in pure swift.
    func testNumber_Double_Exp_Negative() throws {
        // FIXME (vdka): Fix floating point number types
        //XCTAssertEqual(try JSON.parse(from: "-24.3245e-2") as? Double, -24.3245e-2)
    }
    
    func testNumber_Double_ExactnessNoExponent() throws {
        XCTAssertEqual(try JSON.parse(from: "-123451123442342.12124234") as? Double, -123451123442342.12124234)
    }
    
    func testNumber_Double_ExactnessWithExponent() throws {
        XCTAssertEqual(try JSON.parse(from: "-123456789.123456789e-150") as? Double, -123456789.123456789e-150)
    }
    
    func testNumber_Double_Exp_NoFrac() throws {
        XCTAssertEqual(try JSON.parse(from: "24E2") as? Double, 2400.0)
    }
    
    func testNumber_Double_Exp_TwoEs() throws {
        XCTAssertThrowsError(try JSON.parse(from: "-24.3245eE2"))
    }
    
    // MARK: - Strings & Unicode
    
//    func testEscape_Solidus() throws {
//        XCTAssertThrowsError(try JSON.parse(from: "'\\/'") as? String)
//    }
    
    func testLonelyReverseSolidus() throws {
        XCTAssertThrowsError(try JSON.parse(from: "'\\'") as? String)
    }
    
    func testEscape_Unicode_Normal() throws {
        XCTAssertEqual(try JSON.parse(from: "'\\u0048'") as? String, "H")
    }
    
    func testEscape_Unicode_Invalid() {
        XCTAssertThrowsError(try JSON.parse(from: "'\\uD83d\\udQ24'") as? String)
    }
    
    func testEscape_Unicode_Complex() throws {
        XCTAssertEqual(try JSON.parse(from: "'\\ud83d\\ude24'") as? String, "\u{1F624}")
    }
    
    func testEscape_Unicode_Complex_MixedCase() {
        XCTAssertEqual(try JSON.parse(from: "'\\ud83d\\udE24'") as? String, "\u{1F624}")
    }
    
    func testEscape_Unicode_InvalidUnicode_MissingDigit() {
        XCTAssertThrowsError(try JSON.parse(from: "'\\u048'"))
    }
    
    func testEscape_Unicode_InvalidUnicode_MissingAllDigits() {
        XCTAssertThrowsError(try JSON.parse(from: "'\\u'"))
    }
    
    func testString_Empty() {
        XCTAssertEqual(try JSON.parse(from: "''") as? String, "")
    }
    
    func testString_Normal() throws {
        XCTAssertEqual(try JSON.parse(from: "'hello world'") as? String, "hello world")
    }
    
    func testString_Normal_Backslashes() {
        
        // This looks insane and kinda is. The rule is the right side just halve, the left side quarter.
        XCTAssertEqual(try JSON.parse(from: "'C:\\\\\\\\share\\\\path\\\\file'") as? String, "C:\\\\share\\path\\file")
    }
    
    func testString_Normal_WhitespaceInside() {
        XCTAssertEqual(try JSON.parse(from: "'he \\r\\n l \\t l \\n o wo\\rrld '") as? String, "he \r\n l \t l \n o wo\rrld ")
    }
    
    func testString_StartEndWithSpaces() {
        XCTAssertEqual(try JSON.parse(from: "'  hello world  '") as? String, "  hello world  ")
    }
    
    // NOTE(vdka): This cannot be fixed until I find a better way to initialize strings
    func testString_Null() {
        XCTAssertEqual(try JSON.parse(from: "'\\u0000'") as? String, "\u{0000}")
    }
    
    func testString_Unicode_SimpleUnescaped() {
        XCTAssertEqual(try JSON.parse(from: "'€𝄞'") as? String, "€𝄞")
    }
    
    // NOTE(vdka): Swift changes the value if we encode 0xFF into a string.
//    func testString_InvalidUnicodeByte() {
//        
//        let expectedError = JSON.Parser.Error.Reason.invalidUnicode
//        do {
//            
//            let val = try JSON.Parser.parse([quote, 0xFF, quote])
//            
//            XCTFail("expected to throw \(expectedError) but got \(val)")
//        } catch let error as JSON.Parser.Error {
//            
//            XCTAssertEqual(error.reason, expectedError)
//        } catch {
//            
//            XCTFail("expected to throw \(expectedError) but got a different error type!.")
//        }
//    }
    
    func testString_Unicode_NoTrailingSurrogate() {
        XCTAssertThrowsError(try JSON.parse(from: "'\\ud83d'"))
    }
    
    func testString_Unicode_InvalidTrailingSurrogate() {
        XCTAssertThrowsError(try JSON.parse(from: "'\\ud83d\\u0040'"))
    }
    
    func testString_Unicode_RegularChar() {
        XCTAssertEqual(try JSON.parse(from: "'hel\\u006co world'") as? String, "hello world")
    }
    
    func testString_Unicode_SpecialCharacter_CoolA() {
        XCTAssertEqual(try JSON.parse(from: "'h\\u01cdw'") as? String, "hǍw")
    }
    
    func testString_Unicode_SpecialCharacter_HebrewShin() {
        XCTAssertEqual(try JSON.parse(from: "'h\\u05e9w'") as? String, "hשw")
    }
    
    func testString_Unicode_SpecialCharacter_QuarterTo() {
        XCTAssertEqual(try JSON.parse(from: "'h\\u25d5w'") as? String, "h◕w")
    }
    
    func testString_Unicode_SpecialCharacter_EmojiSimple() {
        XCTAssertEqual(try JSON.parse(from: "'h\\ud83d\\ude3bw'") as? String, "h😻w")
    }
    
    func testString_Unicode_SpecialCharacter_EmojiComplex() {
        XCTAssertEqual(try JSON.parse(from: "'h\\ud83c\\udde8\\ud83c\\uddffw'") as? String, "h🇨🇿w")
    }
    
    func testString_SpecialCharacter_QuarterTo() {
        XCTAssertEqual(try JSON.parse(from: "'h◕w'") as? String, "h◕w")
    }
    
    func testString_SpecialCharacter_EmojiSimple() {
        XCTAssertEqual(try JSON.parse(from: "'h😻w'") as? String, "h😻w")
    }
    
    func testString_SpecialCharacter_EmojiComplex() {
        XCTAssertEqual(try JSON.parse(from: "'h🇨🇿w'") as? String, "h🇨🇿w")
    }
    
//    func testString_BackspaceEscape() {
//        let backspace = Character(UnicodeScalar(0x08))
//        XCTAssertThrowsError(try JSON.parse(from: "'\\a'"))
//        
//        expect("'\\b'", toParseTo: String(backspace).encoded())
//    }
//    
//    func testEscape_FormFeed() {
//        XCTAssertThrowsError(try JSON.parse(from: "'\\a'"))
//        let formfeed = Character(UnicodeScalar(0x0C))
//        
//        expect("'\\f'", toParseTo: String(formfeed).encoded())
//        
//    }
//    
//    func testString_ContainingEscapedQuotes() {
//        XCTAssertThrowsError(try JSON.parse(from: "'\\a'"))
//        
//        expect("'\\\"\\\"'", toParseTo: "\"\"")
//    }
    
//    func testString_ContainingSlash() {
//        XCTAssertThrowsError(try JSON.parse(from: "'\\a'"))
//        expect("'http:\\/\\/example.com'", toParseTo: "http://example.com")
//    }
    
    func testString_ContainingInvalidEscape() {
        XCTAssertThrowsError(try JSON.parse(from: "'\\a'"))
    }
    
    
    // MARK: - Objects
    
    func testObject_Empty() throws {
        XCTAssertEqual(try JSONObject(from: "{}"), [:])
    }
    
    func testObject_JustComma() throws {
        XCTAssertThrowsError(try JSONObject(from: "{,}"))
    }
    
    func testObject_SyntaxError() throws {
        XCTAssertThrowsError(try JSONObject(from: "{'hello': 'failure'; 'goodbye': true}"))
    }
    
    func testObject_TrailingComma() throws {
        XCTAssertThrowsError(try JSONObject(from: "{'someKey': true,,}"))
    }
    
    func testObject_MissingComma() throws {
        XCTAssertThrowsError(try JSONObject(from: "{'someKey': true 'someOther': false}"))
    }
    
    func testObject_MissingColon() throws {
        XCTAssertThrowsError(try JSONObject(from: "{'someKey' true}"))
    }
    
    func testObject_Example1() throws {
        XCTAssertEqual(try JSONObject(from: "{\t'hello': 'wor🇨🇿ld', \n\t 'val': 1234, 'many': [\n-12.32, null, 'yo'\r], 'emptyDict': {}, 'dict': {'arr':[]}, 'name': true}"),             [
                "hello": "wor🇨🇿ld",
                "val": 1234,
                "many": [-12.32, Null(), "yo"] as JSONArray,
                "emptyDict": [:] as JSONObject,
                "dict": ["arr": [] as JSONArray] as JSONObject,
                "name": true
            ]
        )
    }
//
//    func testTrollBlockComment() {
//        
//        expect("/*/ {'key':'harry'}", toThrowWithReason: .unmatchedComment, withOptions: .allowComments)
//    }
//    
//    func testLineComment_start() {
//        
//        expect("// This is a comment\n{'key':true}", toParseTo: ["key": true], withOptions: .allowComments)
//    }
//    
//    func testLineComment_endWithNewline() {
//        
//        expect("// This is a comment\n{'key':true}", toParseTo: ["key": true], withOptions: .allowComments)
//        expect("{'key':true}// This is a comment\n", toParseTo: ["key": true], withOptions: .allowComments)
//    }
//    
//    func testLineComment_end() {
//        
//        expect("{'key':true}// This is a comment", toParseTo: ["key": true], withOptions: .allowComments)
//        expect("{'key':true}\n// This is a comment", toParseTo: ["key": true], withOptions: .allowComments)
//    }
//    
//    func testLineComment_withinRootObject() {
//        
//        expect("{\n'key':true,\n// commented!\n'key2':false\n}", toParseTo: ["key": true, "key2": false], withOptions: .allowComments)
//    }
//    
//    func testBlockComment_start() {
//        
//        expect("/* This is a comment */{'key':true}", toParseTo: ["key": true], withOptions: .allowComments)
//    }
//    
//    func testBlockComment_end() throws {
//        let json = try JSONObject(from: "{'key':true}/* This is a comment */")
//        let json2 = try JSONObject(from: "{'key':true}\n/* This is a comment */")
//        
//        XCTAssertEqual(json, ["key": true])
//        XCTAssertEqual(json2, ["key": true])
//    }
//    
//    func testBlockCommentNested() throws {
//        let json = try JSON.parse(from: "[true]/* a /* b */ /* c */ d */")
//        
//        guard let array = json as? JSONArray else {
//            XCTFail()
//            return
//        }
//        
//        XCTAssertEqual(array, [true])
//    }
//    
//    func testBlockComment_withinRootObject() throws {
//        let json = try JSONObject(from: "{'key':true,/* foo */'key2':false/* bar */}")
//        
//        XCTAssertEqual(json.storage["key"] as? Bool, true)
//        XCTAssertEqual(json.storage["key2"] as? Bool, false)
//    }
    
    func testDetailedError() {
        XCTAssertThrowsError(try JSON.parse(from: "0xbadf00d"))
        XCTAssertThrowsError(try JSON.parse(from: "false blah"))
    }
    
    // - MARK: Smoke tests
    
    func testStringParsing() throws {
        let jsonString = "{'hello':'world'}".replacingOccurrences(of: "'", with: "\"")
        
        _ = try JSON.parse(from: jsonString)
    }
}

#if os(Linux)
    extension ParsingTests {
        static var allTests : [(String, (ParsingTests) -> () throws -> Void)] {
            return [
                ("test_FailOnEmpty", testPrepareForReading_FailOnEmpty),
                ("testExtraTokensThrow", testExtraTokensThrow),
                ("testNullParses", testNullParses),
                ("testNullThrowsOnMismatch", testNullThrowsOnMismatch),
                ("testTrueParses", testTrueParses),
                ("testTrueThrowsOnMismatch", testTrueThrowsOnMismatch),
                ("testFalseParses", testFalseParses),
                ("testBoolean_False_Mismatch", testBoolean_False_Mismatch),
                ("testArray_NullsBoolsNums_Normal_Minimal_RootParser", testArray_NullsBoolsNums_Normal_Minimal_RootParser),
                ("testArray_NullsBoolsNums_Normal_MuchWhitespace", testArray_NullsBoolsNums_Normal_MuchWhitespace),
                ("testArray_NullsAndBooleans_Bad_MissingEnd", testArray_NullsAndBooleans_Bad_MissingEnd),
                ("testArray_NullsAndBooleans_Bad_MissingComma", testArray_NullsAndBooleans_Bad_MissingComma),
                ("testArray_NullsAndBooleans_Bad_ExtraComma", testArray_NullsAndBooleans_Bad_ExtraComma),
                ("testArray_NullsAndBooleans_Bad_TrailingComma", testArray_NullsAndBooleans_Bad_TrailingComma),
                ("testNumber_Int_Zero", testNumber_Int_Zero),
                ("testNumber_Int_One", testNumber_Int_One),
                ("testNumber_Int_Basic", testNumber_Int_Basic),
                ("testNumber_Int_Negative", testNumber_Int_Negative),
                ("testNumber_Dbl_Basic", testNumber_Dbl_Basic),
                ("testNumber_Dbl_ZeroSomething", testNumber_Dbl_ZeroSomething),
                ("testNumber_Dbl_MinusZeroSomething", testNumber_Dbl_MinusZeroSomething),
                ("testNumber_Dbl_Incomplete", testNumber_Dbl_Incomplete),
                ("testNumber_Dbl_Negative", testNumber_Dbl_Negative),
                ("testNumber_Dbl_Negative_WrongChar", testNumber_Dbl_Negative_WrongChar),
                ("testNumber_Dbl_Negative_TwoDecimalPoints", testNumber_Dbl_Negative_TwoDecimalPoints),
                ("testNumber_Dbl_Negative_TwoMinuses", testNumber_Dbl_Negative_TwoMinuses),
                ("testNumber_Double_Exp_Normal", testNumber_Double_Exp_Normal),
                ("testNumber_Double_Exp_Positive", testNumber_Double_Exp_Positive),
                ("testNumber_Double_Exp_Negative", testNumber_Double_Exp_Negative),
                ("testNumber_Double_Exp_NoFrac", testNumber_Double_Exp_NoFrac),
                ("testNumber_Double_Exp_TwoEs", testNumber_Double_Exp_TwoEs),
                ("testEscape_Unicode_Normal", testEscape_Unicode_Normal),
                ("testEscape_Unicode_InvalidUnicode_MissingDigit", testEscape_Unicode_InvalidUnicode_MissingDigit),
                ("testEscape_Unicode_InvalidUnicode_MissingAllDigits", testEscape_Unicode_InvalidUnicode_MissingAllDigits),
                ("testString_Empty", testString_Empty),
                ("testString_Normal", testString_Normal),
                ("testString_Normal_WhitespaceInside", testString_Normal_WhitespaceInside),
                ("testString_StartEndWithSpaces", testString_StartEndWithSpaces),
                ("testString_Unicode_RegularChar", testString_Unicode_RegularChar),
                ("testString_Unicode_SpecialCharacter_CoolA", testString_Unicode_SpecialCharacter_CoolA),
                ("testString_Unicode_SpecialCharacter_HebrewShin", testString_Unicode_SpecialCharacter_HebrewShin),
                ("testString_Unicode_SpecialCharacter_QuarterTo", testString_Unicode_SpecialCharacter_QuarterTo),
                ("testString_Unicode_SpecialCharacter_EmojiSimple", testString_Unicode_SpecialCharacter_EmojiSimple),
                ("testString_Unicode_SpecialCharacter_EmojiComplex", testString_Unicode_SpecialCharacter_EmojiComplex),
                ("testString_SpecialCharacter_QuarterTo", testString_SpecialCharacter_QuarterTo),
                ("testString_SpecialCharacter_EmojiSimple", testString_SpecialCharacter_EmojiSimple),
                ("testString_SpecialCharacter_EmojiComplex", testString_SpecialCharacter_EmojiComplex),
                ("testObject_Empty", testObject_Empty),
                ("testObject_Example1", testObject_Example1),
                ("testDetailedError", testDetailedError),
            ]
        }
    }
#endif
