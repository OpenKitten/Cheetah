// Generated using Sourcery 0.7.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT


import XCTest

extension ParsingTests {
  static var allTests: [(String, (ParsingTests) -> () throws -> Void)] = [
    ("test_FailOnEmpty", test_FailOnEmpty),
    ("test_CompletelyWrong", test_CompletelyWrong),
    ("testExtraTokensThrow", testExtraTokensThrow),
    ("testNullParses", testNullParses),
    ("testNullThrowsOnMismatch", testNullThrowsOnMismatch),
    ("testTrueParses", testTrueParses),
    ("testTrueThrowsOnMismatch", testTrueThrowsOnMismatch),
    ("testFalseParses", testFalseParses),
    ("testBoolean_False_Mismatch", testBoolean_False_Mismatch),
    ("testArray_JustComma", testArray_JustComma),
    ("testArray_JustNull", testArray_JustNull),
    ("testArray_ZeroBegining", testArray_ZeroBegining),
    ("testArray_ZeroBeginingWithWhitespace", testArray_ZeroBeginingWithWhitespace),
    ("testArray_NullsBoolsNums_Normal_Minimal_RootParser", testArray_NullsBoolsNums_Normal_Minimal_RootParser),
    ("testArray_NullsBoolsNums_Normal_MuchWhitespace", testArray_NullsBoolsNums_Normal_MuchWhitespace),
    ("testArray_NullsAndBooleans_Bad_MissingEnd", testArray_NullsAndBooleans_Bad_MissingEnd),
    ("testArray_NullsAndBooleans_Bad_MissingComma", testArray_NullsAndBooleans_Bad_MissingComma),
    ("testArray_NullsAndBooleans_Bad_ExtraComma", testArray_NullsAndBooleans_Bad_ExtraComma),
    ("testArray_NullsAndBooleans_Bad_TrailingComma", testArray_NullsAndBooleans_Bad_TrailingComma),
    ("testNumber_Int_ZeroWithTrailingWhitespace", testNumber_Int_ZeroWithTrailingWhitespace),
    ("testNumber_Int_Zero", testNumber_Int_Zero),
    ("testNumber_Int_One", testNumber_Int_One),
    ("testNumber_Int_Basic", testNumber_Int_Basic),
    ("testNumber_IntMin", testNumber_IntMin),
    ("testNumber_IntMax", testNumber_IntMax),
    ("testNumber_Int_Negative", testNumber_Int_Negative),
    ("testNumber_Int_Garbled", testNumber_Int_Garbled),
    ("testNumber_Int_Overflow", testNumber_Int_Overflow),
    ("testNumber_Double_Overflow", testNumber_Double_Overflow),
    ("testNumber_Dbl_Basic", testNumber_Dbl_Basic),
    ("testNumber_Dbl_ZeroSomething", testNumber_Dbl_ZeroSomething),
    ("testNumber_Dbl_MinusZeroSomething", testNumber_Dbl_MinusZeroSomething),
    ("testNumber_Dbl_ThrowsOnMinus", testNumber_Dbl_ThrowsOnMinus),
    ("testNumber_Dbl_MinusDecimal", testNumber_Dbl_MinusDecimal),
    ("testNumber_Dbl_Incomplete", testNumber_Dbl_Incomplete),
    ("testNumber_Dbl_Negative", testNumber_Dbl_Negative),
    ("testNumber_Dbl_Negative_WrongChar", testNumber_Dbl_Negative_WrongChar),
    ("testNumber_Dbl_Negative_TwoDecimalPoints", testNumber_Dbl_Negative_TwoDecimalPoints),
    ("testNumber_Dbl_Negative_TwoMinuses", testNumber_Dbl_Negative_TwoMinuses),
    ("testNumber_Double_ZeroExpOne", testNumber_Double_ZeroExpOne),
    ("testNumber_Double_Exp_Normal", testNumber_Double_Exp_Normal),
    ("testNumber_Double_Exp_Positive", testNumber_Double_Exp_Positive),
    ("testNumber_Double_Exp_Negative", testNumber_Double_Exp_Negative),
    ("testNumber_Double_ExactnessNoExponent", testNumber_Double_ExactnessNoExponent),
    ("testNumber_Double_ExactnessNoExponent", testNumber_Double_ExactnessNoExponent),
    ("testNumber_Double_ExactnessWithExponent", testNumber_Double_ExactnessWithExponent),
    ("testNumber_Double_Exp_NoFrac", testNumber_Double_Exp_NoFrac),
    ("testNumber_Double_Exp_TwoEs", testNumber_Double_Exp_TwoEs),
    ("testLonelyReverseSolidus", testLonelyReverseSolidus),
    ("testEscape_Unicode_Normal", testEscape_Unicode_Normal),
    ("testEscape_Unicode_Invalid", testEscape_Unicode_Invalid),
    ("testEscape_Unicode_Complex", testEscape_Unicode_Complex),
    ("testEscape_Unicode_Complex_MixedCase", testEscape_Unicode_Complex_MixedCase),
    ("testEscape_Unicode_InvalidUnicode_MissingDigit", testEscape_Unicode_InvalidUnicode_MissingDigit),
    ("testEscape_Unicode_InvalidUnicode_MissingAllDigits", testEscape_Unicode_InvalidUnicode_MissingAllDigits),
    ("testString_Empty", testString_Empty),
    ("testString_Normal", testString_Normal),
    ("testString_Normal_Backslashes", testString_Normal_Backslashes),
    ("testString_Normal_WhitespaceInside", testString_Normal_WhitespaceInside),
    ("testString_StartEndWithSpaces", testString_StartEndWithSpaces),
    ("testString_Null", testString_Null),
    ("testString_Unicode_SimpleUnescaped", testString_Unicode_SimpleUnescaped),
    ("testString_Unicode_NoTrailingSurrogate", testString_Unicode_NoTrailingSurrogate),
    ("testString_Unicode_InvalidTrailingSurrogate", testString_Unicode_InvalidTrailingSurrogate),
    ("testString_Unicode_RegularChar", testString_Unicode_RegularChar),
    ("testString_Unicode_SpecialCharacter_CoolA", testString_Unicode_SpecialCharacter_CoolA),
    ("testString_Unicode_SpecialCharacter_HebrewShin", testString_Unicode_SpecialCharacter_HebrewShin),
    ("testString_Unicode_SpecialCharacter_QuarterTo", testString_Unicode_SpecialCharacter_QuarterTo),
    ("testString_Unicode_SpecialCharacter_EmojiSimple", testString_Unicode_SpecialCharacter_EmojiSimple),
    ("testString_Unicode_SpecialCharacter_EmojiComplex", testString_Unicode_SpecialCharacter_EmojiComplex),
    ("testString_SpecialCharacter_QuarterTo", testString_SpecialCharacter_QuarterTo),
    ("testString_SpecialCharacter_EmojiSimple", testString_SpecialCharacter_EmojiSimple),
    ("testString_SpecialCharacter_EmojiComplex", testString_SpecialCharacter_EmojiComplex),
    ("testString_ContainingInvalidEscape", testString_ContainingInvalidEscape),
    ("testObject_Empty", testObject_Empty),
    ("testObject_JustComma", testObject_JustComma),
    ("testObject_SyntaxError", testObject_SyntaxError),
    ("testObject_TrailingComma", testObject_TrailingComma),
    ("testObject_MissingComma", testObject_MissingComma),
    ("testObject_MissingColon", testObject_MissingColon),
    ("testObject_Example1", testObject_Example1),
    ("testDetailedError", testDetailedError),
    ("testStringParsing", testStringParsing),
    ("testDoubleSmallDecimal", testDoubleSmallDecimal)
  ]
}
extension SerializerBenchmarks {
  static var allTests: [(String, (SerializerBenchmarks) -> () throws -> Void)] = [
    ("testDeserializationPerformance", testDeserializationPerformance),
    ("testSerializerPerformance", testSerializerPerformance),
    ("testSerializerPrettyPrintedPerformance", testSerializerPrettyPrintedPerformance),
    ("testSerializerFoundationPerformance", testSerializerFoundationPerformance),
    ("testSerializerFoundationPrettyPrintedPerformance", testSerializerFoundationPrettyPrintedPerformance)
  ]
}

// swiftlint:disable trailing_comma
XCTMain([
  testCase(ParsingTests.allTests),
  testCase(SerializerBenchmarks.allTests),
])
// swiftlint:enable trailing_comma

