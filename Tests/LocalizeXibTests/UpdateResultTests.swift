@testable import LocalizeXib
import XCTest

final class UpdateResultTests: XCTestCase {
    static var allTests = [
        ("test_registerUnknownKey_addsTheKey", test_registerUnknownKey_addsTheKey),
        ("test_registerReplacedKey_addsTheKeyAndValue", test_registerReplacedKey_addsTheKeyAndValue)
    ]

    func test_registerUnknownKey_addsTheKey() throws {
        var result = UpdateResult()
        result.registerUnknownKey("key")
        XCTAssertEqual(result.unknownKeys, ["key"])
    }

    func test_registerReplacedKey_addsTheKeyAndValue() throws {
        var result = UpdateResult()
        result.registerReplacedKey("key", value: "value")
        XCTAssertEqual(result.replacedKeys, ["key": "value"])
    }
}
