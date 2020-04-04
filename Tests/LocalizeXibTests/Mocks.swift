@testable import LocalizeXibCore
import class Foundation.NSError

class MockFileSystem: FileSystem {
    var files: [String: String] = [:]

    func fileExists(atPath path: String) -> Bool {
        files[path] != nil
    }

    func contents(ofFile path: String) throws -> String {
        guard let contents = files[path] else {
            throw NSError(domain: "", code: 999, userInfo: nil)
        }
        return contents
    }

    func write(_ string: String, to filePath: String) throws {
        files[filePath] =  string
    }

    func addFile(path: String, contents: String) {
        files[path] = contents
    }
}
