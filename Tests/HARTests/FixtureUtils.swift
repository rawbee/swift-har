import XCTest

let fixtureURL: URL = {
    var url = URL(fileURLWithPath: #file)
    url.appendPathComponent("../../Fixtures")
    url.standardize()
    return url
}()

let fixtureData: [String: Data] = {
    try! FileManager.default
        .contentsOfDirectory(atPath: fixtureURL.path)
        .reduce(into: [String: Data]()) { fixtures, name in
            fixtures[name] = try! Data(contentsOf: fixtureURL.appendingPathComponent(name))
        }
}()
