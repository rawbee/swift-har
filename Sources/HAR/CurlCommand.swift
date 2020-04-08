import Foundation

extension HAR {
    public struct CurlCommand: CustomStringConvertible {
        var url: URL
        var method: String
        var headers: [(name: String, value: String)]
        var cookies: [(name: String, value: String)]

        init(
            url: URL, method: String = "GET", headers: [(name: String, value: String)] = [],
            cookies: [(name: String, value: String)] = []
        ) {
            self.url = url
            self.method = method
            self.headers = headers
            self.cookies = cookies
        }

        init(request: Request) {
            self.url = request.url
            self.method = request.method
            self.headers = request.headers.removingAll(name: "Cookie").map {
                (name: $0.name, value: $0.value)
            }
            self.cookies = request.cookies.map { (name: $0.name, value: $0.value) }
        }

        public var description: String {
            var lines: [String] = []

            lines.append("curl '\(url)'")

            if method != "GET" {
                lines.append("--request \(method)")
            }

            for (name, value) in headers {
                lines.append("--header '\(name): \(value)'")
            }

            for (name, value) in cookies {
                lines.append("--cookie '\(name)=\(value)'")
            }

            return lines.joined(separator: " \\\n  ")
        }
    }
}
