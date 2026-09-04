import XCTest

public extension XCTestCase {
    /// Fails the test at teardown if `instance` is still alive.
    ///
    /// Call it for every view model and every view controller a test constructs.
    /// A leak is a build failure here, not a finding for later.
    func trackForMemoryLeaks(_ instance: AnyObject,
                             file: StaticString = #filePath,
                             line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance,
                         "Instance was not deallocated. Potential retain cycle.",
                         file: file,
                         line: line)
        }
    }
}
