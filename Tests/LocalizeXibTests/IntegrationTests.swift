import XCTest
import PathKit

final class IntegrationTests: XCTestCase {
    static var allTests = [
        ("test_happyPath", test_happyPath),
        ("test_noInputFiles_throwsError", test_noInputFiles_throwsError),
        ("test_noLocalizableFiles_throwsError", test_noLocalizableFiles_throwsError)
    ]

    /// Returns the path to the built products directory.
    private var productsDirectory: URL {
      #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
      #else
        return Bundle.main.bundleURL
      #endif
    }

    static var fixturesDirectory: Path!
    var testDirectory: Path!

    override class func setUp() {
        IntegrationTests.fixturesDirectory =  Path.current + "Tests" + "Fixtures"
    }

    override func setUp() {
        let tempDirectory = try! Path.uniqueTemporary()
        let testDirectory = tempDirectory + "Fixtures"
        try! IntegrationTests.fixturesDirectory.copy(testDirectory)
        self.testDirectory = testDirectory
    }

    func test_happyPath() throws {
        try run(args: ["./en.lproj/Localizable.strings", "./nl.lproj/Localizable.strings"], pwd: testDirectory.string)

        XCTAssertEqual(
            try String(contentsOfFile: (testDirectory + "en.lproj/Main.strings").string),
            """
            "TTJ-tj-MN7.normalTitle" = "This is the button title";
            "bcg-Rc-DAi.text" = "Welcome to localize-xibs";
            "pAx-Te-oS9.normalTitle" = "Weird \\" characters \\ \\n";
            """
        )

        XCTAssertEqual(
            try String(contentsOfFile: (testDirectory + "nl.lproj/Main.strings").string),
            """
            "TTJ-tj-MN7.normalTitle" = "De is de knoptitel";
            "bcg-Rc-DAi.text" = "Welkom bij localize-xibs";
            "pAx-Te-oS9.normalTitle" = "Rare \\" karakters \\ \\n";
            """
        )
    }

    func test_noInputFiles_throwsError() throws {
        let output = try run(pwd: try! Path.uniqueTemporary().string)
        XCTAssertEqual(output.stderr, "Error: No input files specified. Run localize-xib -h for usage.\n")
    }

    func test_noLocalizableFiles_throwsError() throws {
        let output = try run(args: ["./en.lproj/Localizable.strings"], pwd: try! Path.uniqueTemporary().string)
        XCTAssertEqual(output.stderr, "Error: No localizable XIBs or Storyboards were found. Make sure you use Base Internationalization and your XIBs and Storyboards are located in Base.lproj directories.\n")
    }

    @discardableResult
    private func run(args: [String] = [], pwd: String) throws -> (stdout: String?, stderr: String?) {
        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            fatalError("Integration tests are not supported on macOS versions lower than 10.13")
        }

        print("Running in: \(pwd)")

        let fileManager = FileManager.default
        fileManager.changeCurrentDirectoryPath(pwd)

        let process = Process()
        process.executableURL = productsDirectory.appendingPathComponent("localize-xibs")
        process.arguments = args

        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe

        let stderrPipe = Pipe()
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        return (
            stdout: String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8),
            stderr: String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
        )
    }
}
