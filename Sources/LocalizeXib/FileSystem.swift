@_implementationOnly import Foundation
import PathKit

protocol FileSystemProtocol {
    func fileExists(atPath: String) -> Bool
    func contents(ofFile: String) throws -> String
    func write(_ string: String, to: String) throws
    func glob(_ pattern: String) -> [String]
}

struct FileSystem: FileSystemProtocol {
    func fileExists(atPath path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    func contents(ofFile file: String) throws -> String {
        try String(contentsOfFile: file)
    }

    func write(_ string: String, to filePath: String) throws {
        try string.write(to: URL(fileURLWithPath: filePath), atomically: true, encoding: .utf8)
    }

    func glob(_ pattern: String) -> [String] {
        Path.glob(pattern).map(\.string)
    }
}
