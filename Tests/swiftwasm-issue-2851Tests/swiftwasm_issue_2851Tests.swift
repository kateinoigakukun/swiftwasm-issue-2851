import XCTest
@testable import swiftwasm_issue_2851

final class swiftwasm_issue_2851Tests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(swiftwasm_issue_2851().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
