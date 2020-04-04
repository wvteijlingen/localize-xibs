@_implementationOnly import Foundation

private extension String {
    var fileURL: URL { URL(fileURLWithPath: self) }
}

public enum Error: Swift.Error {
    case generic
    case fileNotLocalized
    case noInputsSpecified
}

/// A file that is localized by Xcode and sits inside an *.lproj directory.
protocol LocalizedFile {
    /// The path to the file.
    var filePath: String { get }

    /// The locale's language code of the file's contents, as derived from the .lproj directory name.
    var locale: String { get }

    /// The human readable language name of the file's contents, in English.
    /// Example: For a file with locale `nl`, this would be `Dutch`.
    var language: String { get }

    /// The name of the file without the file extension.
    var name: String { get }

    /// The name of the file including the file extension.
    var nameAndExtension: String { get }
}

extension LocalizedFile {
    var locale: String {
        filePath.fileURL.deletingLastPathComponent().deletingPathExtension().lastPathComponent
    }
    var language: String {
        Locale(identifier: "en").localizedString(forLanguageCode: locale) ?? locale
    }
    var name: String {
        filePath.fileURL.deletingPathExtension().lastPathComponent
    }
    var nameAndExtension: String {
        filePath.fileURL.lastPathComponent
    }
}

/// A XIB or Storyboard file.
struct InterfaceBuilderFile: LocalizedFile {
    let filePath: String
    let fileSystem: FileSystemProtocol

    init(filePath: String, fileSystem: FileSystemProtocol) throws {
        guard filePath.fileURL.deletingLastPathComponent().lastPathComponent.hasSuffix(".lproj") else {
            throw Error.fileNotLocalized
        }
        self.filePath = filePath
        self.fileSystem = fileSystem
    }

    /// The .strings file for the given locale belonging to this file, or nil if no such file exists.
    ///
    /// Example: If the receiver represents the file `Root/Base.lproj/Main.xib`,
    /// and this method is called with `locale: nl`, this would return a `StringsFile`
    /// representing `Root/nl.lproj/Main.strings` if such a file exists.
    func stringsFile(withLocale locale: String) -> StringsFile? {
        let path = filePath
            .fileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("\(locale).lproj")
            .appendingPathComponent("\(name).strings")

        guard fileSystem.fileExists(atPath: path.path) else { return nil }

        return try? StringsFile(filePath: path.path, fileSystem: fileSystem)
    }
}

/// A .strings file.
struct StringsFile: LocalizedFile {
    let filePath: String
    let fileSystem: FileSystemProtocol

    init(filePath: String, fileSystem: FileSystemProtocol) throws {
        guard filePath.fileURL.deletingLastPathComponent().lastPathComponent.hasSuffix(".lproj") else {
            throw Error.fileNotLocalized
        }
        self.filePath = filePath
        self.fileSystem = fileSystem
    }

    /// All keys and values in this file.
    func keysAndValues() throws -> [String: String] {
        let data = try String(contentsOfFile: filePath)
        let lines = data.components(separatedBy: .newlines)
        let keysWithValues: [(String, String)] = lines.compactMap { line in
            // https://whatdidilearn.info/2018/07/29/how-to-capture-regex-group-values-in-swift.html
            guard
                let regex = try? NSRegularExpression(pattern: #""(.+)" = "(.*)";"#),
                let match = regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count)),
                let keyRange = Range(match.range(at: 1), in: line),
                let valueRange = Range(match.range(at: 2), in: line)
            else {
                return nil
            }

            return (String(line[keyRange]), String(line[valueRange]))
        }
        return Dictionary(uniqueKeysWithValues: keysWithValues)
    }

    /// Updates the file by replacing the given values with their replacements.
    /// - note: The keys in the replacements dictionary are not the keys in the .strings file,
    ///         but the existing values in the .strings file.
    @discardableResult func update(withReplacements replacements: [String: String]) throws -> UpdateResult {
        let data = try String(contentsOfFile: filePath)
        let inputLines = data.components(separatedBy: .newlines)

        var updateResult = UpdateResult()

        let outputLines = inputLines.map { (line) -> String in
            guard
                let regex = try? NSRegularExpression(pattern: #"("[^"]+" = ")t:([^"]*)(";)"#),
                let match = regex.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.utf16.count)),
                let preRange = Range(match.range(at: 1), in: line),
                let keyRange = Range(match.range(at: 2), in: line),
                let postRange = Range(match.range(at: 3), in: line)
            else {
                return line
            }

            let pre = String(line[preRange])
            let key = String(line[keyRange])
            let post = String(line[postRange])

            if let replacement = replacements[key] {
                updateResult.registerReplacedKey(key, value: replacement)
                return "\(pre)\(replacement)\(post)"
            } else {
                updateResult.registerUnknownKey(key)
                return "\(pre)__\(key)__\(post)"
            }
        }

        try outputLines.joined(separator: "\n").write(toFile: filePath, atomically: true, encoding: .utf8)

        return updateResult
    }
}

struct UpdateResult {
    var unknownKeys: [String] = []
    var replacedKeys: [String: String] = [:]

    mutating func registerUnknownKey(_ key: String) {
        unknownKeys.append(key)
    }

    mutating func registerReplacedKey(_ key: String, value: String) {
        replacedKeys[key] = value
    }
}
