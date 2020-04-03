import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        [
            testCase(LocalizeXibTests.allTests),
        ]
    }
#endif
