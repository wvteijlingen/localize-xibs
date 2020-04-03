@_implementationOnly import Foundation

enum Error: Swift.Error {
    case inputFileNotLocalized
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

struct TranslationSource: CustomStringConvertible {
    let filePath: URL
    let locale: String
    let translations: [String: String]

    init(filePath: String) throws {
        let pathURL = URL(fileURLWithPath: filePath)

        guard pathURL.deletingLastPathComponent().lastPathComponent.hasSuffix(".lproj") else {
            throw Error.inputFileNotLocalized
        }

        let stringsFile = StringsFile(filePath: pathURL)

        self.filePath = pathURL
        self.locale = pathURL.deletingLastPathComponent().deletingPathExtension().lastPathComponent
        self.translations = try stringsFile.keysAndValues()
    }

    var description: String {
        translations.map { (key, value) -> String in
            "\(key) = \(value)"
        }.joined(separator: "\n")
    }
}

struct OutputXib {
    let filePath: URL

    var name: String {
         filePath.deletingPathExtension().lastPathComponent
    }

    var nameAndExtension: String {
         filePath.lastPathComponent
    }

    func stringsFile(withLocale locale: String) -> StringsFile? {
        let path = filePath
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("\(locale).lproj")
            .appendingPathComponent("\(name).strings")

        guard FileManager.default.fileExists(atPath: path.path) else { return nil }

        return StringsFile(filePath: path)
    }
}

struct StringsFile {
    let filePath: URL

    func keysAndValues() throws -> [String: String] {
        let data = try String(contentsOf: filePath)
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

    func update(withTranslations translations: [String: String]) throws -> UpdateResult {
        let data = try! String(contentsOf: filePath)
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

            if let translation = translations[key] {
                updateResult.registerReplacedKey(key, value: translation)
                return "\(pre)\(translation)\(post)"
            } else {
                updateResult.registerUnknownKey(key)
                return "\(pre)__\(key)__\(post)"
            }
        }

        try outputLines.joined(separator: "\n").write(to: filePath, atomically: true, encoding: .utf8)

        return updateResult
    }
}
