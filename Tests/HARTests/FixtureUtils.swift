import XCTest

let fixtureURL: URL = {
    var url = URL(fileURLWithPath: #file)
    url.appendPathComponent("../../Fixtures")
    url.standardize()
    return url
}()

let fixtureData: [String: Data] = {
    try! FileManager.default
        .contentsOfDirectory(at: fixtureURL)
        .reduce(into: [String: Data]()) { fixtures, url in
            fixtures[url.lastPathComponent] = try! Data(contentsOf: url)
        }
}()

private extension FileManager {
    /// - Bug: Reading directories seems buggy under Xcode's XCTest. Try a few times 🤷🏻‍♂️
    func contentsOfDirectory(at url: URL, tries: Int = 3) throws -> [URL] {
        do {
            return try contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
        } catch {
            if tries <= 1 {
                throw error
            }
            return try contentsOfDirectory(at: url, tries: tries - 1)
        }
    }
}
