@testable import LocalizeXibCore
import XCTest

class StringsFileTests: XCTestCase {
    static var allTests = [
        ("test_init_throwsErrorWhenFileIsNotInLprojDirectory", test_init_throwsErrorWhenFileIsNotInLprojDirectory),
        ("test_keysAndValues_parsesAllKeysAndValuesFromTheFile", test_keysAndValues_parsesAllKeysAndValuesFromTheFile),
        ("test_update_updatesValuesWithReplacements", test_update_updatesValuesWithReplacements),
        ("test_update_marksValuesWithoutReplacements", test_update_marksValuesWithoutReplacements),
        ("test_update_returnsAnUpdateResult", test_update_returnsAnUpdateResult),
    ]

    var fs: MockFileSystem!

    override func setUp() {
        super.setUp()

        fs = MockFileSystem()
        fs.addFile(path: "/en.lproj/Localizable.strings", contents:
            """
            /* First comment */
            "key1" = "t:foo";

            /* Second comment */
            "key2" = "t:bar";

            /* Third comment */
            "key3" = "bar";
            """
        )
    }

    func test_init_throwsErrorWhenFileIsNotInLprojDirectory() {
        XCTAssertThrowsError(try StringsFile(filePath: "/Localizable.strings", fileSystem: fs)) { error in
//            guard let error = error as? Error.fileNotLocalized else {
//                XCTFail()
//            }
        }
    }

    func test_keysAndValues_parsesAllKeysAndValuesFromTheFile() {
        let file = try! StringsFile(filePath: "/en.lproj/Localizable.strings", fileSystem: fs)
        let actual = try? file.keysAndValues()
        let expected = ["key1": "t:foo", "key2": "t:bar", "key3": "bar"]
        XCTAssertEqual(actual, expected)
    }

    func test_update_updatesValuesWithReplacements() {
        let file = try! StringsFile(filePath: "/en.lproj/Localizable.strings", fileSystem: fs)
        try! file.update(withReplacements: ["foo": "NewFoo", "bar": "NewBar"])
        let actual = fs.files["/en.lproj/Localizable.strings"]
        let expected =
        """
        /* First comment */
        "key1" = "NewFoo";

        /* Second comment */
        "key2" = "NewBar";

        /* Third comment */
        "key3" = "bar";
        """
        XCTAssertEqual(actual, expected)
    }

    func test_update_marksValuesWithoutReplacements() {
        let file = try! StringsFile(filePath: "/en.lproj/Localizable.strings", fileSystem: fs)
        try! file.update(withReplacements: ["foo": "NewFoo"])
        let actual = fs.files["/en.lproj/Localizable.strings"]
        let expected =
        """
        /* First comment */
        "key1" = "NewFoo";

        /* Second comment */
        "key2" = "__bar__";

        /* Third comment */
        "key3" = "bar";
        """
        XCTAssertEqual(actual, expected)
    }

    func test_update_returnsAnUpdateResult() {
        let file = try! StringsFile(filePath: "/en.lproj/Localizable.strings", fileSystem: fs)
        let result = try? file.update(withReplacements: [
            "foo": "NewFoo",

        ])
        XCTAssertEqual(result?.unknownKeys,["bar"])
        XCTAssertEqual(result?.replacedKeys, ["foo": "NewFoo"])
    }
}
