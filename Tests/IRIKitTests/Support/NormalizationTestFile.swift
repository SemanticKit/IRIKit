import Foundation

/// One version of the Unicode conformance file NormalizationTest.txt, copied
/// unchanged into the test resources by Scripts/UnicodeTables/generate.py.
struct NormalizationTestFile: Sendable {
    /// One line of the file: the five columns c1 to c5 as code points.
    struct Line: Sendable {
        let part: String
        let columns: [[Unicode.Scalar]]
        let lineNumber: Int
    }

    let lines: [Line]

    /// The single code points that Part 1 lists.
    let partOneCodePoints: Set<UInt32>

    init(version: String) throws {
        guard let url = Bundle.module.url(forResource: "NormalizationTest-\(version)", withExtension: "txt") else {
            throw CocoaError(.fileNoSuchFile)
        }
        let text = try String(contentsOf: url, encoding: .utf8)
        var part = ""
        var lines: [Line] = []
        var partOne: Set<UInt32> = []
        for (index, rawLine) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let content = rawLine.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false).first ?? ""
            if content.hasPrefix("@") {
                part = String(content.split(separator: " ").first ?? "")
                continue
            }
            let fields = content.split(separator: ";", omittingEmptySubsequences: false)
            guard fields.count >= 5 else {
                continue
            }
            let columns = fields.prefix(5).map { field in
                field.split(separator: " ").map { Unicode.Scalar(UInt32($0, radix: 16)!)! }
            }
            if part == "@Part1", columns[0].count == 1 {
                partOne.insert(columns[0][0].value)
            }
            lines.append(Line(part: part, columns: columns, lineNumber: index + 1))
        }
        self.lines = lines
        partOneCodePoints = partOne
    }
}
