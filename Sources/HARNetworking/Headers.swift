import HAR

/// Split comma seperated Set-Cookie header values.
///
/// HTTPURLResponse does not support multiple headers with the same same. Thus, multiple
/// Set-Cookie headers are join with a comma. Simpling splitting by a comma won't work
/// as it's common for Expire values to include commas in the date string.
///
/// Adapted from `HTTPCookie.cookies(withResponseHeaderFields:for:)`.
/// https://github.com/apple/swift-corelibs-foundation/blob/6167997/Foundation/HTTPCookie.swift#L438
///
private func splitCookieValue(_ cookies: String) -> [String] {
    var values: [String] = []

    func isSpace(_ c: Character) -> Bool {
        c == " " || c == "\t" || c == "\n" || c == "\r"
    }

    func isTokenCharacter(_ c: Character) -> Bool {
        guard let asciiValue = c.asciiValue else {
            return false
        }

        // CTL, 0-31 and DEL (127)
        if asciiValue <= 31 || asciiValue >= 127 {
            return false
        }

        let nonTokenCharacters = "()<>@,;:\\\"/[]?={} \t"
        return !nonTokenCharacters.contains(c)
    }

    var idx = cookies.startIndex
    let end = cookies.endIndex
    while idx < end {
        while idx < end, isSpace(cookies[idx]) {
            idx = cookies.index(after: idx)
        }
        let cookieStartIdx = idx
        var cookieEndIdx = idx

        while idx < end {
            let cookiesRest = cookies[idx ..< end]
            if let commaIdx = cookiesRest.firstIndex(of: ",") {
                var lookaheadIdx = cookies.index(after: commaIdx)
                while lookaheadIdx < end, isSpace(cookies[lookaheadIdx]) {
                    lookaheadIdx = cookies.index(after: lookaheadIdx)
                }
                var tokenLength = 0
                while lookaheadIdx < end, isTokenCharacter(cookies[lookaheadIdx]) {
                    lookaheadIdx = cookies.index(after: lookaheadIdx)
                    tokenLength += 1
                }
                while lookaheadIdx < end, isSpace(cookies[lookaheadIdx]) {
                    lookaheadIdx = cookies.index(after: lookaheadIdx)
                }
                if lookaheadIdx < end, cookies[lookaheadIdx] == "=", tokenLength > 0 {
                    idx = cookies.index(after: commaIdx)
                    cookieEndIdx = commaIdx
                    break
                }
                idx = cookies.index(after: commaIdx)
                cookieEndIdx = idx
            } else {
                idx = end
                cookieEndIdx = end
                break
            }
        }

        if cookieEndIdx <= cookieStartIdx {
            continue
        }

        values.append(String(cookies[cookieStartIdx ..< cookieEndIdx]))
    }

    return values
}

extension HAR.Headers {
    // MARK: Initializers

    public init(_ fields: [AnyHashable: Any]) {
        self = fields.flatMap { (name, value) -> Self in
            guard let name = name as? String, let value = value as? String else {
                return []
            }

            let header = HAR.Header(name: name, value: value)
            if header.isNamed("Set-Cookie") {
                return splitCookieValue(header.value).map { value in
                    HAR.Header(name: header.name, value: value)
                }
            } else {
                return [header]
            }
        }
    }
}
