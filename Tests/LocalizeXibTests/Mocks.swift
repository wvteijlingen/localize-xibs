@testable import LocalizeXib

class MockFileSystem: FileSystemProtocol {
    var files: [String: String] = [:]
    var globFiles: Set<String> = []

    func fileExists(atPath path: String) -> Bool {
        files[path] != nil
    }

    func contents(ofFile path: String) throws -> String {
        guard let contents = files[path] else {
            throw LocalizeXib.Error.generic
        }
        return contents
    }

    func write(_ string: String, to filePath: String) throws {
        files[filePath] =  string
    }

    func glob(_ pattern: String) -> [String] {
        Array(globFiles)
    }

    func addFile(path: String, contents: String) {
        files[path] = contents
    }

    func addGlob(path: String) {
        globFiles.insert(path)
    }
}
