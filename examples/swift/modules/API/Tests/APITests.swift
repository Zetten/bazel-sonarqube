import API
import XCTest

final class APITests: XCTestCase {
    func test_success() {
        XCTAssertTrue(API.returnTrue())
    }
}
