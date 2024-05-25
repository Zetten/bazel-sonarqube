@testable import Models
import XCTest

final class ModelsTests: XCTestCase {
    func test_success() {
        XCTAssertTrue(ModelA().internalBoolFunction())
    }
}
