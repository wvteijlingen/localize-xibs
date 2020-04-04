import XCTest

import LocalizeXibTests

var tests = [XCTestCaseEntry]()
tests += InterfaceBuilderFileTests.allTests()
tests += StringsFileTests.allTests()
tests += UpdateResultTests.allTests()
tests += IntegrationTests.allTests()
XCTMain(tests)
