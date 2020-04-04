import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        [
            testCase(StringsFileTests.allTests),
            testCase(InterfaceBuilderFileTests.allTests),
            testCase(UpdateResultTests.allTests),
        ]
    }
#endif
