import XCTest
import RouterKit
import FeatureSample
@testable import AppCore

final class PendingDeepLinkStoreTests: XCTestCase {
    func test_consumeClearsTheStoreSoALinkCannotReplayTwice() {
        let store = PendingDeepLinkStore()
        store.stash([SampleHomeRoute()])
        XCTAssertFalse(store.isEmpty)

        XCTAssertEqual(store.consume().count, 1)
        XCTAssertTrue(store.isEmpty, "A stale pending link is a live production defect")
        XCTAssertTrue(store.consume().isEmpty)
    }

    func test_parsedApproveLinkCarriesTheWholeStackAndNoPII() throws {
        let url = try XCTUnwrap(URL(string: "byon://sample/approve?reference=TRX-000123"))
        let link = try XCTUnwrap(AppDeepLinks.parse(url))
        XCTAssertEqual(link.stack.count, 2, "Back must land on the dashboard without it being the entry")
        XCTAssertTrue(link.isAuthenticationRequired)
        XCTAssertEqual(link.identifier, "sample.approve")
    }

    func test_unknownSchemeIsNotParsed() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/sample"))
        XCTAssertNil(AppDeepLinks.parse(url))
    }
}
