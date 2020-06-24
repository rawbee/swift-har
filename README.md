# Swift HAR (HTTP Archive)

A Swift library for encoding, decoding, recording and testing using the [HTTP Archive format](http://www.softwareishard.com/blog/har-12-spec/).

## Examples

### Decoding HAR files

The main `HAR` module includes the functionality to read and write `.har` files from disk.

```swift
import HAR

let archive = try HAR(contentsOf: URL(fileURLWithPath: "/path/to/example.har"))

archive.log.entries[0].request.url

try archive.write(to: URL(fileURLWithPath: "/other/example.har"))
```

### Recording a HAR from an `URLSession`

The `HARNetworking` has additional functionality around the `URLSession`, `URLRequest` and `HTTPURLResponse` types. (Note that on Linux, this depends `FoundationNetworking`)

A new HTTP archive can be created by recording the HTTP request and response from an actual `URLSession` request.

```swift
import HARNetworking

let url = URL(string: "http://example.com/")!
let request = URLRequest(url: url)

HAR.record(request: request) { (result: Result<HAR, Error>) in
    let archive = try! result.get()
    print(archive.log.entries[0].request.url)
}
```

### Using a HAR as a mock response in tests

Furthermore, `HARTesting` provides networking and testing helpers for use only in a test target. (It depends on `XCTest`)

```swift
import HARTesting
import XCTest

final class FooTests: XCTestCase {
    func testRequest() throws {
        let archiveFileURL = URL(fileURLWithPath: "/path/to/example.har")

        let url = URL(string: "http://example.com")!
        let urlRequest = URLRequest(url: url)

        // If example.har exists, load it offline. Otherwise make an online request and save it as an archive.
        let result = awaitHTTPURLRequest(urlRequest, mockedWith: archiveFileURL)

        let (data, response) = try result.get()
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(data.count, 1256)
    }
}
```
