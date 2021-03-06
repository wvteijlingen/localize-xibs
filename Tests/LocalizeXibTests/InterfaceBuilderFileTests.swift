@testable import LocalizeXibCore
import XCTest

final class InterfaceBuilderFileTests: XCTestCase {
    static var allTests = [
        ("test_stringsFile_returnsStringsFileIfItExists", test_stringsFile_returnsStringsFileIfItExists),
        ("test_stringsFile_returnsNilIfItDoesNotExist", test_stringsFile_returnsNilIfItDoesNotExist)
    ]

    var fs: MockFileSystem!

    override func setUp() {
        super.setUp()
        fs = MockFileSystem()
        fs.addFile(path: "/Base.lproj/Main.xib", contents: "")
    }

    func test_init_throwsErrorWhenFileIsNotInLprojDirectory() {
        XCTAssertThrowsError(try InterfaceBuilderFile(filePath: "/Main.xib", fileSystem: fs)) { error in
            switch error {
            case LocalizeXibCore.Error.fileNotLocalized(let filePath):
                XCTAssertEqual(filePath, "/Main.xib")
            default:
                XCTFail()
            }
        }
    }

    func test_stringsFile_returnsStringsFileIfItExists() throws {
        fs.addFile(path: "/en.lproj/Main.strings", contents: "")
        let file = try InterfaceBuilderFile(filePath: "/Base.lproj/Main.xib", fileSystem: fs)
        let result = file.stringsFile(forLocale: "en")

        XCTAssertEqual(result?.filePath, "/en.lproj/Main.strings")
    }

    func test_stringsFile_returnsNilIfItDoesNotExist() throws {
        let file = try InterfaceBuilderFile(filePath: "/Base.lproj/Main.xib", fileSystem: fs)
        let result = file.stringsFile(forLocale: "en")

        XCTAssertNil(result)
    }
}
