@testable import LocalizeXib
import XCTest

class StringsFileTests: XCTestCase {
    static var allTests = [
        ("test_init_throwsErrorWhenFileIsNotInLprojDirectory", test_init_throwsErrorWhenFileIsNotInLprojDirectory),
        ("test_keysAndValues_parsesAllKeysAndValuesFromTheFile", test_keysAndValues_parsesAllKeysAndValuesFromTheFile),
        ("test_update_updatesValueswithReplacements", test_update_updatesValueswithReplacements),
        ("test_update_leavesValuesWithoutReplacements", test_update_leavesValuesWithoutReplacements),
        ("test_update_returnsAnUpdateResult", test_update_returnsAnUpdateResult),
    ]

    var fs: MockFileSystem!

    override func setUp() {
        super.setUp()

        fs = MockFileSystem()
        fs.addFile(path: "en.lproj/Localizable.strings", contents:
            """
            /* A comment */
            "key1" = "Foo";

            /* Another comment */
            "key2" = "Bar";
            """
        )
    }

    func test_init_throwsErrorWhenFileIsNotInLprojDirectory() {
        XCTAssertThrowsError(try StringsFile(filePath: "Localizable.strings", fileSystem: fs)) { error in
//            guard let error = error as? Error.fileNotLocalized else {
//                XCTFail()
//            }
        }
    }

    func test_keysAndValues_parsesAllKeysAndValuesFromTheFile() {
        let file = try! StringsFile(filePath: "en.lproj/Localizable.strings", fileSystem: fs)
        let actual = try? file.keysAndValues()
        let expected = ["key1": "Foo", "key2": "Bar"]
        XCTAssertEqual(actual, expected)
    }

    func test_update_updatesValueswithReplacements() {
        let file = try! StringsFile(filePath: "en.lproj/Localizable.strings", fileSystem: fs)
        try! file.update(withReplacements: ["Foo": "NewFoo", "Bar": "NewBar"])
        let actual = fs.files["en.lproj/Localizable.strings"]
        let expected =
        """
        /* A comment */
        "key1" = "NewFoo";

        /* Another comment */
        "key2" = "NewBar";
        """
        XCTAssertEqual(actual, expected)
    }

    func test_update_leavesValuesWithoutReplacements() {
        let file = try! StringsFile(filePath: "en.lproj/Localizable.strings", fileSystem: fs)
        try! file.update(withReplacements: ["Foo": "NewFoo"])
        let actual = fs.files["en.lproj/Localizable.strings"]
        let expected =
        """
        /* A comment */
        "key1" = "NewFoo";

        /* Another comment */
        "key2" = "Bar";
        """
        XCTAssertEqual(actual, expected)
    }

    func test_update_returnsAnUpdateResult() {
        let file = try! StringsFile(filePath: "en.lproj/Localizable.strings", fileSystem: fs)
        let result = try? file.update(withReplacements: [
            "Foo": "NewFoo",

        ])
        XCTAssertEqual(result?.unknownKeys,["Bar"])
        XCTAssertEqual(result?.replacedKeys, ["Foo": "NewFoo"])
    }
}
