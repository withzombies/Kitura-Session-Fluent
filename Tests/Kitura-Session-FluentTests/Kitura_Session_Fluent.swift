import XCTest
@testable import Kitura_Session_Fluent

class Kitura_Session_FluentTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(Kitura_Session_Fluent().text, "Hello, World!")
    }


    static var allTests : [(String, (Kitura_Session_FluentTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
