import XCTest
import PathKit

final class IntegrationTests: XCTestCase {
    static var allTests = [
        ("test_integration", test_integration)
    ]

    var testDirectory: String!

    override func setUp() {
        let tempDirectory = try! Path.uniqueTemporary()
        testDirectory = tempDirectory + "Fixtures"
        let fixtures = Path.current + "Tests" + "Fixtures"
        try! fixtures.copy(testDirectory)
    }

    func test_integration() throws {
        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            return
        }

        // Make the temp directory the current working directory
        let fileManager = FileManager.default
        fileManager.changeCurrentDirectoryPath(testDirectory.path)

        let process = Process()
        process.executableURL = productsDirectory.appendingPathComponent("localize-xibs")
        process.arguments = ["./en.lproj/Localizable.strings", "./nl.lproj/Localizable.strings"]

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)

        print(output)

//        XCTAssertEqual(output, "Hello, world!\n")
    }

    /// Returns path to the built products directory.
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
