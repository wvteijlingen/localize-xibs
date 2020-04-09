import Foundation

protocol FileSystem {
    func fileExists(atPath: String) -> Bool
    func contents(ofFile: String) -> Data?
    func write(_ string: String, to: String) throws
}

struct DefaultFileSystem: FileSystem {
    func fileExists(atPath path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    func contents(ofFile file: String) -> Data? {
        FileManager.default.contents(atPath: file)
    }

    func write(_ string: String, to filePath: String) throws {
        try string.write(to: URL(fileURLWithPath: filePath), atomically: true, encoding: .utf8)
    }
}
