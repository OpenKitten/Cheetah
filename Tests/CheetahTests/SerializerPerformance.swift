
import XCTest
import Cheetah

let largeJsonData = loadFixture("large")
let largeJsonFoundationData = loadFixtureData("large")

let largeJson = try! JSON.parse(from: largeJsonData)

class SerializerBenchmarks: XCTestCase {

  override func setUp() {
    super.setUp()
    _ = largeJson.serialize()
  }
    
    func testDeserializationPerformance() throws {
        measure {
            _ = try! JSON.parse(from: largeJsonData)
        }
    }

  func testSerializerPerformance() {

    measure {
        _ = largeJson.serialize()
    }
  }

  func testSerializerPrettyPrintedPerformance() {

    measure {
        _ = largeJson.serialize()
    }
  }

  func testSerializerFoundationPerformance() {

    let nsJson = try! JSONSerialization.jsonObject(with: largeJsonFoundationData, options: [])

    measure {
      do {
        try JSONSerialization.data(withJSONObject: nsJson, options: [])
      } catch { XCTFail() }
    }
  }

  func testSerializerFoundationPrettyPrintedPerformance() {

    let nsJson = try! JSONSerialization.jsonObject(with: largeJsonFoundationData, options: [])

    measure {
      do {
        try JSONSerialization.data(withJSONObject: nsJson, options: .prettyPrinted)
      } catch { XCTFail() }
    }
  }
}
