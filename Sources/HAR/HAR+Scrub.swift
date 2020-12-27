import class Foundation.NSRegularExpression

// MARK: Redacting sensitive data

public extension HAR {
    static let sensitiveHeaders = try! NSRegularExpression(
        pattern: #"auth|cookie|key|passsword|secret|token"#,
        options: .caseInsensitive
    )

    enum ScrubOperation {
        case redactHeader(name: String, placeholder: String)
        case redactHeaderMatching(pattern: NSRegularExpression, placeholder: String)
        case removeHeader(name: String)
        case removeHeaderMatching(pattern: NSRegularExpression)
        case stripTimmings
    }

    mutating func scrub(_ operations: [ScrubOperation]) {
        log.scrub(operations)
    }

    func scrubbing(_ operations: [ScrubOperation]) -> Self {
        var copy = self
        copy.scrub(operations)
        return copy
    }
}

public extension HAR.Entry {
    mutating func scrub(_ operations: [HAR.ScrubOperation]) {
        for operation in operations {
            switch operation {
            case .stripTimmings:
                time = -1
                timings = HAR.Timing()
            default:
                continue
            }
        }

        request.scrub(operations)
        response.scrub(operations)
    }

    func scrubbing(_ operations: [HAR.ScrubOperation]) -> Self {
        var copy = self
        copy.scrub(operations)
        return copy
    }
}

public extension HAR.Log {
    mutating func scrub(_ operations: [HAR.ScrubOperation]) {
        if var pages = pages {
            for index in pages.indices {
                pages[index].scrub(operations)
            }
            self.pages = pages
        }

        for index in entries.indices {
            entries[index].scrub(operations)
        }
    }

    func scrubbing(_ operations: [HAR.ScrubOperation]) -> Self {
        var copy = self
        copy.scrub(operations)
        return copy
    }
}

public extension HAR.Page {
    mutating func scrub(_ operations: [HAR.ScrubOperation]) {
        for operation in operations {
            switch operation {
            case .stripTimmings:
                pageTimings = HAR.PageTiming()
            default:
                continue
            }
        }
    }

    func scrubbing(_ operations: [HAR.ScrubOperation]) -> Self {
        var copy = self
        copy.scrub(operations)
        return copy
    }
}

public extension HAR.Request {
    mutating func scrub(_ operations: [HAR.ScrubOperation]) {
        let oldCookieValue = headers.value(forName: "Cookie")

        headers.scrub(operations)

        if let newCookieValue = headers.value(forName: "Cookie"), newCookieValue != oldCookieValue {
            for index in cookies.indices {
                cookies[index].value = newCookieValue
            }
        }
    }

    func scrubbing(_ operations: [HAR.ScrubOperation]) -> Self {
        var copy = self
        copy.scrub(operations)
        return copy
    }
}

public extension HAR.Response {
    mutating func scrub(_ operations: [HAR.ScrubOperation]) {
        let oldSetCookieValue = headers.value(forName: "Set-Cookie")

        headers.scrub(operations)

        if let newSetCookieValue = headers.value(forName: "Set-Cookie"),
           newSetCookieValue != oldSetCookieValue
        {
            for index in cookies.indices {
                cookies[index].value = newSetCookieValue
            }
        }
    }

    func scrubbing(_ operations: [HAR.ScrubOperation]) -> Self {
        var copy = self
        copy.scrub(operations)
        return copy
    }
}

public extension HAR.Headers {
    mutating func removeAll(name: String) {
        removeAll(where: { $0.isNamed(name) })
    }

    func removingAll(name: String) -> Self {
        var copy = self
        copy.removeAll(name: name)
        return copy
    }

    mutating func scrub(_ operations: [HAR.ScrubOperation]) {
        for operation in operations {
            switch operation {
            case .redactHeader(let name, let placeholder):
                for index in indices {
                    if self[index].isNamed(name) {
                        self[index].value = placeholder
                    }
                }
            case .redactHeaderMatching(let pattern, let placeholder):
                for index in indices {
                    if self[index].isNamed(pattern) {
                        self[index].value = placeholder
                    }
                }
            case .removeHeader(let name):
                removeAll(where: { $0.isNamed(name) })
            case .removeHeaderMatching(let pattern):
                removeAll(where: { $0.isNamed(pattern) })
            case .stripTimmings:
                continue
            }
        }
    }

    func scrubbing(_ operations: [HAR.ScrubOperation]) -> Self {
        var copy = self
        copy.scrub(operations)
        return copy
    }
}
