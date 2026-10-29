@testable import IRIKit
import Testing

@Suite("Unicode Normalization Forms conformance (UAX #15 NormalizationTest.txt)")
struct UnicodeNormalizationConformanceTests {
    static let versions: [(data: UnicodeNormalizationData, file: String)] = [
        (.unicode18_0, "18.0.0"),
        (.unicode3_2, "3.2.0"),
    ]

    @Test(
        "Every line of NormalizationTest.txt meets the conformance invariants for NFC, NFD, NFKC and NFKD.",
        .tags(.unicodeNormalization),
        arguments: ["18.0.0", "3.2.0"]
    )
    func conformanceInvariants(_ version: String) throws {
        let data = try #require(Self.versions.first { $0.file == version }?.data)
        #expect(data.version == version)
        let file = try NormalizationTestFile(version: version)
        #expect(file.lines.count > 15_000)

        var failures: [Int] = []
        for line in file.lines {
            let c = line.columns
            func form(_ text: [Unicode.Scalar], _ form: UnicodeNormalizationForm) -> [UInt32] {
                data.normalized(text, form).map(\.value)
            }
            let v = c.map { $0.map(\.value) }
            let holds =
                // c2 == NFC(c1) == NFC(c2) == NFC(c3), c4 == NFC(c4) == NFC(c5)
                [c[0], c[1], c[2]].allSatisfy { form($0, .nfc) == v[1] }
                && [c[3], c[4]].allSatisfy { form($0, .nfc) == v[3] }
                // c3 == NFD(c1) == NFD(c2) == NFD(c3), c5 == NFD(c4) == NFD(c5)
                && [c[0], c[1], c[2]].allSatisfy { form($0, .nfd) == v[2] }
                && [c[3], c[4]].allSatisfy { form($0, .nfd) == v[4] }
                // c4 == NFKC(c1..c5), c5 == NFKD(c1..c5)
                && c.allSatisfy { form($0, .nfkc) == v[3] }
                && c.allSatisfy { form($0, .nfkd) == v[4] }
            if !holds {
                failures.append(line.lineNumber)
            }
        }
        #expect(failures.isEmpty, "NormalizationTest-\(version).txt lines \(failures.prefix(20))")
    }

    @Test(
        "Every code point that Part 1 does not list normalizes to itself in every form.",
        .tags(.unicodeNormalization),
        arguments: ["18.0.0", "3.2.0"]
    )
    func unlistedCodePointsAreInvariant(_ version: String) throws {
        let data = try #require(Self.versions.first { $0.file == version }?.data)
        let file = try NormalizationTestFile(version: version)

        var failures: [UInt32] = []
        for value in UInt32(0)...0x10FFFF where !(0xD800...0xDFFF).contains(value) {
            guard !file.partOneCodePoints.contains(value) else {
                continue
            }
            let scalar = [Unicode.Scalar(value)!]
            for form in UnicodeNormalizationForm.allCases where data.normalized(scalar, form) != scalar {
                failures.append(value)
                break
            }
        }
        #expect(failures.isEmpty, "code points \(failures.prefix(20).map { String($0, radix: 16) })")
    }
}
