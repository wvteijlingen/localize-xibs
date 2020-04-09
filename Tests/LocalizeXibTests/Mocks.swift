@testable import LocalizeXibCore
import Foundation

class MockFileSystem: FileSystem {
    var files: [String: String] = [:]

    func fileExists(atPath path: String) -> Bool {
        files[path] != nil
    }

    func contents(ofFile path: String) -> Data? {
        guard let contents = files[path] else { return nil }
        return contents.data(using: .utf8)
    }

    func write(_ string: String, to filePath: String) throws {
        files[filePath] =  string
    }

    func addFile(path: String, contents: String) {
        files[path] = contents
    }
}
