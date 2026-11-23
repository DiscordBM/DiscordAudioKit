import Foundation

enum FixtureLoader {

    static func url(named name: String) -> URL {
        if let moduleUrl = Bundle.module.url(
            forResource: name,
            withExtension: nil,
            subdirectory: "Fixtures"
        ) {
            return moduleUrl
        }
        if let moduleUrl = Bundle.module.url(forResource: name, withExtension: nil) {
            return moduleUrl
        }
        let currentFile = URL(fileURLWithPath: #filePath)
        let fixturesDir =
            currentFile
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures", isDirectory: true)
        return fixturesDir.appendingPathComponent(name)
    }

    static func path(named name: String) -> String {
        url(named: name).path
    }

    static func load(named name: String) throws -> [UInt8] {
        let fileUrl = url(named: name)
        let data = try Data(contentsOf: fileUrl)
        return [UInt8](data)
    }
}
