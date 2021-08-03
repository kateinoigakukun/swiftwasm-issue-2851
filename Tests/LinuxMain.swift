import XCTest

import swiftwasm_issue_2851Tests

var tests = [XCTestCaseEntry]()
tests += swiftwasm_issue_2851Tests.allTests()
XCTMain(tests)
