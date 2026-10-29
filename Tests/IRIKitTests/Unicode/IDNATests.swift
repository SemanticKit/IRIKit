@testable import IRIKit
import Testing

@Suite("IDNA ToASCII and ToUnicode (RFC 3490 section 4) and Punycode (RFC 3492)")
struct IDNATests {
    private func scalars(_ text: String) -> [Unicode.Scalar] {
        Array(text.unicodeScalars)
    }

    private func string(_ scalars: [Unicode.Scalar]) -> String {
        var view = String.UnicodeScalarView()
        view.append(contentsOf: scalars)
        return String(view)
    }

    @Test(
        "Punycode decodes and encodes every sample string of RFC 3492 section 7.1.",
        .tags(.idna),
        arguments: PunycodeSample.rfc3492
    )
    func punycodeSamples(_ sample: PunycodeSample) throws {
        #expect(Punycode.decode(sample.punycode) == sample.unicode)
        // The samples use optional mixed-case annotations (RFC 3492
        // appendix A); IRIKit's encoder writes lowercase digits.
        let encoded = try #require(Punycode.encode(sample.unicode))
        #expect(string(scalars(encoded).map(IDNA.asciiLowercased)) == string(scalars(sample.punycode).map(IDNA.asciiLowercased)))
        #expect(Punycode.decode(encoded) == sample.unicode)
    }

    @Test(
        "ToASCII gives the lowercase ACE label of each RFC 3492 sample, or fails where STD3 or the length limit says so.",
        .tags(.idna),
        arguments: PunycodeSample.rfc3492
    )
    func toASCIIOfSamples(_ sample: PunycodeSample) {
        let result = IDNA.toASCII(scalars(sample.unicode)).map(string)
        if sample.isValidLabel {
            #expect(result == "xn--" + string(scalars(sample.punycode).map(IDNA.asciiLowercased)))
        } else {
            #expect(result == nil)
        }
    }

    @Test(
        "ToASCII and ToUnicode convert the RFC 3987 section 5.3.3 example label.",
        .tags(.idna)
    )
    func rfc3987Example() {
        #expect(IDNA.toASCII(scalars("r\u{E9}sum\u{E9}")).map(string) == "xn--rsum-bpad")
        #expect(string(IDNA.toUnicode(scalars("xn--rsum-bpad"))) == "r\u{E9}sum\u{E9}")
        // ToUnicode compares the ACE label case-insensitively (step 7) and
        // returns the decoded text, whose basic code points keep their case.
        #expect(string(IDNA.toUnicode(scalars("XN--RSUM-BPAD"))) == "R\u{E9}SUM\u{E9}")
    }

    @Test(
        "ToASCII applies UseSTD3ASCIIRules (RFC 3490 section 4.1 step 3).",
        .tags(.idna),
        arguments: ["-abc", "abc-", "a_b", "a b", "a.b", "a%41", "\u{FF05}41", "b\u{FC}cher-", "\u{2488}"]
    )
    func std3Rules(_ label: String) {
        #expect(IDNA.toASCII(scalars(label)) == nil)
    }

    @Test(
        "ToASCII leaves an ASCII label as it is and rejects a non-ASCII label that starts with the ACE prefix (steps 4 and 5).",
        .tags(.idna)
    )
    func asciiAndACEPrefix() {
        #expect(IDNA.toASCII(scalars("Example")).map(string) == "Example")
        #expect(IDNA.toASCII(scalars("xn--bcher-kva")).map(string) == "xn--bcher-kva")
        #expect(IDNA.toASCII(scalars("xn--b\u{FC}cher")) == nil)
        // Fullwidth "xn--" maps to the ACE prefix under NFKC; the result is
        // ASCII, so step 4 skips step 5 and the label passes unchanged.
        #expect(IDNA.toASCII(scalars("\u{FF58}\u{FF4E}--bcher-kva")).map(string) == "xn--bcher-kva")
    }

    @Test(
        "ToASCII accepts 1 to 63 code points (step 8).",
        .tags(.idna)
    )
    func lengthLimit() {
        #expect(IDNA.toASCII([]) == nil)
        #expect(IDNA.toASCII(scalars(String(repeating: "a", count: 63))) != nil)
        #expect(IDNA.toASCII(scalars(String(repeating: "a", count: 64))) == nil)
        #expect(IDNA.toASCII(scalars(String(repeating: "a", count: 55) + "\u{FC}")).map { $0.count } == 63)
        #expect(IDNA.toASCII(scalars(String(repeating: "a", count: 56) + "\u{FC}")) == nil)
        #expect(IDNA.toASCII(scalars(String(repeating: "\u{FC}", count: 60))) == nil)
    }

    @Test(
        "ToUnicode never fails and returns its input when the label is not a valid ACE label (RFC 3490 section 4.2).",
        .tags(.idna),
        arguments: ["example", "xn--", "xn--a-", "xn--invalid-", "xn--a-ecp", "xn--abc", "a\u{1680}b"]
    )
    func toUnicodeReturnsInputOnFailure(_ label: String) {
        #expect(string(IDNA.toUnicode(scalars(label))) == label)
    }
}
