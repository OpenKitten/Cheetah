//
//import XCTest
//import Foundation
//@testable import Cheetah
//
//class JSONTests: XCTestCase {
//  
//  let json: JSON =
//    [
//      "name": "Bob", "age": 51, "nice": true, "hairy": false, "height": 182.43,
//      "pets": ["Harry", "Peter"] as JSON,
//      "roles": [
//        ["title": "Developer", "timeSpent": 2] as JSON,
//        ["title": "Student", "timeSpent": 3] as JSON
//      ] as JSON
//    ]
//  
//  func testKaas() throws {
//    let string = "  { \"key\" : \"value with emoji 👍\", \"  num \": 312.15213568e-2  , \"arrAY\": [\"0\", 0, \"true\" , true  ,\"bob\",false,\"meep\", null ] } "
//    
//    for _ in 0..<10_000 {
//      _ = try JSON.Parser.parse(string)
//    }
//  }
//  
//  func testSanity() {
//    
//    func assertSymmetricJSONConversion(_ json: JSON, options: JSON.Serializer.Option = [], line: UInt = #line) {
//      do {
//        let json2 = try JSON.Parser.parse(json.serialized(options: options))
//        XCTAssertEqual(json, json2, line: line)
//      } catch {
//        XCTFail(line: line)
//      }
//    }
//    
//    assertSymmetricJSONConversion([1, [2, 3] as JSON])
//
//    assertSymmetricJSONConversion([1, 25])
//    assertSymmetricJSONConversion(["key": "value", "key2": 2]) // TODO: Investigate
//    
//    assertSymmetricJSONConversion([])
//    assertSymmetricJSONConversion([], options: [.prettyPrint])
//    assertSymmetricJSONConversion([:])
//    assertSymmetricJSONConversion([:], options: [.prettyPrint])
//    assertSymmetricJSONConversion([[:] as JSON, [:] as JSON])
//    
//    assertSymmetricJSONConversion(json)
//    assertSymmetricJSONConversion(["symbols": "œ∑´®†¥¨ˆøπ“‘«åß∂ƒ©˙∆˚¬…æΩ≈ç√∫˜µ≤≥÷Œ„´‰ˇÁ¨ˆØ∏”’»ÅÍÎÏ˝ÓÔÒÚÆ¸˛Ç◊ı˜Â¯˘¿"])
//    assertSymmetricJSONConversion(["emojis": "👍🏽🍉🇦🇺"])
//    assertSymmetricJSONConversion(["👍🏽", "🍉", "🇦🇺"])
//    
//  }
//  
//  func testAccessors() {
//    XCTAssertEqual(json["name"].string, "Bob")
//    XCTAssertEqual(json["age"].int, 51)
//    XCTAssertEqual(json["nice"].bool, true)
//    XCTAssertEqual(json["hairy"].bool, false)
//    XCTAssertEqual(json["height"].double, 182.43)
//    XCTAssertEqual(json["pets"].array?.flatMap({ $0.string }) ?? [], ["Harry", "Peter"])
//    XCTAssertEqual(json["pets"][0].string, "Harry")
//    XCTAssertEqual(json["pets"][1].string, "Peter")
//    XCTAssertEqual(json["roles"][0]["title"].string, "Developer")
//    XCTAssertEqual(json["roles"][0]["timeSpent"].int, 2)
//    XCTAssertEqual(json["roles"][1]["title"].string, "Student")
//    XCTAssertEqual(json["roles"][1]["timeSpent"].int, 3)
//    XCTAssertEqual(json["roles"][0].object!, ["title": .string("Developer"), "timeSpent": .integer(2)])
//    XCTAssertEqual(json["roles"][1].object!, ["title": .string("Student"), "timeSpent": .integer(3)])
//    
//    XCTAssertEqual(json["name"].int, nil)
//    XCTAssertEqual(json["name"].bool, nil)
//    XCTAssertEqual(json["name"].int64, nil)
//    XCTAssertEqual(json["name"].double, nil)
//    XCTAssertEqual(json["roles"][1000], nil)
//    XCTAssertEqual(json[0], nil)
//  }
//  
//  func testMutation() {
//    var json: JSON = ["height": 1.90, "array": [1, 2, 3] as JSON]
//    XCTAssertEqual(json["height"].double, 1.90)
//    json["height"] = 1.91
//    XCTAssertEqual(json["height"].double, 1.91)
//    
//    XCTAssertEqual(json["array"][0], 1)
//    json["array"][0] = 4
//    XCTAssertEqual(json["array"], [4, 2, 3])
//  }
//}
//
//#if os(Linux)
//  extension JSONTests: XCTestCaseProvider {
//    var allTests : [(String, () throws -> Void)] {
//      return [
//        ("testSerializeArray", testSerializeArray),
//        ("testParse", testParse),
//        ("testSanity", testSanity),
//        ("testAccessors", testAccessors),
//        ("testMutation", testMutation),
//      ]
//    }
//  }
//#endif
