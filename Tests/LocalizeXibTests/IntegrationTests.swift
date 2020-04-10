import XCTest

final class IntegrationTests: XCTestCase {
    static var allTests = [
        ("test_happyPath", test_happyPath),
        ("test_noInputFiles_printsErrorToStrErr", test_noInputFiles_printsErrorToStrErr),
        ("test_noStrictArgument_printsWarningsToStdOut", test_noStrictArgument_printsWarningsToStdOut),
        ("test_strictArgument_printsErrorsToStdErr", test_strictArgument_printsErrorsToStdErr),
        ("test_noLocalizableFiles_printsWarningToStdOut", test_noLocalizableFiles_printsWarningToStdOut),
        ("test_missingTranslation_printsWarningToStdErr", test_missingTranslation_printsWarningToStdErr),
        ("test_missingTranslationInStrictMode_printsErrorToStdErr", test_missingTranslationInStrictMode_printsErrorToStdErr),
        ("test_verboseArgument_printsTranslationsToStdOut", test_verboseArgument_printsTranslationsToStdOut)
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

    static var fixturesDirectory: URL!

    override class func setUp() {
        fixturesDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("Tests")
            .appendingPathComponent("Fixtures")
    }

    private func uniqueTestDirectory(withFixtures: Bool) -> URL {
        let fileManager = FileManager.default

        let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try! fileManager.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true, attributes: nil)

        let testDirectory = temporaryDirectory.appendingPathComponent("Fixtures")

        if withFixtures {
            try! fileManager.copyItem(at: Self.fixturesDirectory, to: testDirectory)
        } else {
            try! fileManager.createDirectory(at: testDirectory, withIntermediateDirectories: true, attributes: nil)
        }

        return testDirectory
    }

    func test_happyPath() throws {
        let testDirectory = uniqueTestDirectory(withFixtures: true)

        try run(
            args: ["./en.lproj/Localizable.strings", "./nl.lproj/Localizable.strings"],
            pwd: testDirectory.path
        )

        XCTAssertEqual(
            try String(contentsOfFile: testDirectory.appendingPathComponent("en.lproj/Main.strings").path),
            """
            "TTJ-tj-MN7.normalTitle" = "This is the button title";
            "bcg-Rc-DAi.text" = "Welcome to localize-xibs";
            "pAx-Te-oS9.normalTitle" = "Weird \\" characters \\ \\n";
            "wxy-TL-Rt3.normalTitle" = "__missing_translation__";
            """
        )

        XCTAssertEqual(
            try String(contentsOfFile: testDirectory.appendingPathComponent("nl.lproj/Main.strings").path),
            """
            "TTJ-tj-MN7.normalTitle" = "De is de knoptitel";
            "bcg-Rc-DAi.text" = "Welkom bij localize-xibs";
            "pAx-Te-oS9.normalTitle" = "Rare \\" karakters \\ \\n";
            "wxy-TL-Rt3.normalTitle" = "__missing_translation__";
            """
        )

        XCTAssertEqual(
            try String(contentsOfFile: testDirectory.appendingPathComponent("Subdirectory/en.lproj/Main.strings").path),
            """
            "TTJ-tj-MN7.normalTitle" = "This is the button title";
            "bcg-Rc-DAi.text" = "Welcome to localize-xibs";
            "pAx-Te-oS9.normalTitle" = "Weird \\" characters \\ \\n";
            "wxy-TL-Rt3.normalTitle" = "__missing_translation__";
            """
        )

        XCTAssertEqual(
            try String(contentsOfFile: testDirectory.appendingPathComponent("Subdirectory/nl.lproj/Main.strings").path),
            """
            "TTJ-tj-MN7.normalTitle" = "De is de knoptitel";
            "bcg-Rc-DAi.text" = "Welkom bij localize-xibs";
            "pAx-Te-oS9.normalTitle" = "Rare \\" karakters \\ \\n";
            "wxy-TL-Rt3.normalTitle" = "__missing_translation__";
            """
        )
    }

    func test_noLocalizableFiles_printsWarningToStdOut() throws {
        let output = try run(
            args: ["./en.lproj/Localizable.strings"],
            pwd: uniqueTestDirectory(withFixtures: false).path
        )
        XCTAssertEqual(output.stdout, "warning: No localizable XIBs or Storyboards were found. Make sure you use Base Internationalization and your XIBs and Storyboards are located in Base.lproj directories.\n")
    }

    func test_noInputFiles_printsErrorToStrErr() throws {
        let output = try run(pwd: uniqueTestDirectory(withFixtures: false).path)
        XCTAssert(output.stderr.contains("Error: No input files specified"))
    }

    func test_noStrictArgument_printsWarningsToStdOut() throws {
        let output = try run(args: ["./en.lproj/NoSuchFile.strings"], pwd:  uniqueTestDirectory(withFixtures: true).path)
        XCTAssertTrue(output.stdout.contains("warning: The file ./en.lproj/NoSuchFile.strings could not be loaded."))
    }

    func test_strictArgument_printsErrorsToStdErr() throws {
        let output = try run(args: ["./en.lproj/NoSuchFile.strings", "--strict"], pwd:  uniqueTestDirectory(withFixtures: true).path)
        XCTAssertTrue(output.stderr.contains("error: The file ./en.lproj/NoSuchFile.strings could not be loaded."))
    }

    func test_missingTranslation_printsWarningToStdErr() throws {
        let testDirectory = uniqueTestDirectory(withFixtures: true)
        let output = try run(
            args: ["./en.lproj/Localizable.strings", "./nl.lproj/Localizable.strings"],
            pwd: testDirectory.path
        )

        XCTAssertTrue(output.stdout.contains("warning: Unknown translation for \"missing_translation\""))
    }

    func test_missingTranslationInStrictMode_printsErrorToStdErr() throws {
        let testDirectory = uniqueTestDirectory(withFixtures: true)
        let output = try run(
            args: ["./en.lproj/Localizable.strings", "./nl.lproj/Localizable.strings", "--strict"],
            pwd: testDirectory.path
        )

        XCTAssertTrue(output.stderr.contains("error: Unknown translation for \"missing_translation\""))
    }

    func test_verboseArgument_printsTranslationsToStdOut() throws {
        let testDirectory = uniqueTestDirectory(withFixtures: true)
        let output = try run(
            args: ["./en.lproj/Localizable.strings", "--verbose"],
            pwd: testDirectory.path
        )

        XCTAssertTrue(output.stdout.contains("Translated \"title\" with \"Welcome to localize-xibs\""))
    }

    @discardableResult
    private func run(args: [String] = [], pwd: String) throws -> (stdout: String, stderr: String) {
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
            stdout: String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "",
            stderr: String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        )
    }
}
