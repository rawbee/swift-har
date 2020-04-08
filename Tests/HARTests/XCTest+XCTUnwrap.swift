import XCTest

struct XCTestErrorWhileUnwrappingOptional: Error {}

func XCTUnwrap<T>(
    _ expression: @autoclosure () throws -> T?, _ message: @autoclosure () -> String = "",
    file: StaticString = #file, line: UInt = #line
) throws -> T {
    if let value = try expression() {
        return value
    }

    let providedMessage = message()
    let failureMessage =
        providedMessage.isEmpty
            ? "Expected non-nil value of type \"\(String(describing: T.self))\"" : providedMessage

    XCTFail(failureMessage, file: file, line: line)
    throw XCTestErrorWhileUnwrappingOptional()
}
