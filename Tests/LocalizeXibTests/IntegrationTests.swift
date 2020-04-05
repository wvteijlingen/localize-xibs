import XCTest
import PathKit

final class IntegrationTests: XCTestCase {
    static var allTests = [
        ("test_happyPath", test_happyPath)
    ]

    var testDirectory: Path!

    override func setUp() {
        let tempDirectory = try! Path.uniqueTemporary()
        let testDirectory = tempDirectory + "Fixtures"
        let fixtures = Path.current + "Tests" + "Fixtures"
        try! fixtures.copy(testDirectory)
        self.testDirectory = testDirectory
        print("Test directory: \(testDirectory)")
    }

    func test_happyPath() throws {
        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            return
        }

        // Make the temp directory the current working directory
        let fileManager = FileManager.default
        fileManager.changeCurrentDirectoryPath(testDirectory.string)

        let process = Process()
        process.executableURL = productsDirectory.appendingPathComponent("localize-xibs")
        process.arguments = ["./en.lproj/Localizable.strings", "./nl.lproj/Localizable.strings"]

        try process.run()
        process.waitUntilExit()

        XCTAssertEqual(
            try! String(contentsOfFile: (testDirectory + "en.lproj/Main.strings").string),
            """
            "TTJ-tj-MN7.normalTitle" = "This is the button title";
            "bcg-Rc-DAi.text" = "Welcome to localize-xibs";
            "pAx-Te-oS9.normalTitle" = "Weird \\" characters \\ \\n";
            """
        )

        XCTAssertEqual(
            try! String(contentsOfFile: (testDirectory + "nl.lproj/Main.strings").string),
            """
            "TTJ-tj-MN7.normalTitle" = "De is de knoptitel";
            "bcg-Rc-DAi.text" = "Welkom bij localize-xibs";
            "pAx-Te-oS9.normalTitle" = "Rare \\" karakters \\ \\n";
            """
        )
    }

    /// Returns the path to the built products directory.
    var productsDirectory: URL {
      #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
      #else
        return Bundle.main.bundleURL
      #endif
    }
}
