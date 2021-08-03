import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(swiftwasm_issue_2851Tests.allTests),
    ]
}
#endif
