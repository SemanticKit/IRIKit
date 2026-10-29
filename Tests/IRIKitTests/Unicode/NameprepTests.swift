@testable import IRIKit
import Testing

@Suite("Nameprep (RFC 3491), the stringprep profile of RFC 3454")
struct NameprepTests {
    private func prepare(_ text: String) -> String? {
        Nameprep.prepare(Array(text.unicodeScalars)).map { scalars in
            var view = String.UnicodeScalarView()
            view.append(contentsOf: scalars)
            return String(view)
        }
    }

    @Test(
        "Table B.1 maps its characters to nothing (RFC 3454 section 3, RFC 3491 section 3).",
        .tags(.idna),
        arguments: [
            ("b\u{00AD}\u{FC}cher", "b\u{FC}cher"),
            ("a\u{200B}b", "ab"),
            ("a\u{200C}b\u{200D}c", "abc"),
            ("a\u{FE0F}b\u{FEFF}", "ab"),
            ("\u{034F}a\u{180B}", "a"),
        ]
    )
    func tableB1MapsToNothing(_ input: String, _ expected: String) {
        #expect(prepare(input) == expected)
    }

    @Test(
        "Table B.2 case-folds for NFKC, including the full case folding of sharp s (RFC 3454 section 3, RFC 3491 section 3).",
        .tags(.idna),
        arguments: [
            ("stra\u{DF}e", "strasse"),
            ("STRASSE", "strasse"),
            ("\u{3A3}\u{3C2}", "\u{3C3}\u{3C3}"),
            ("\u{FB01}x", "fix"),
            ("\u{210C}", "h"),
            ("\u{1D400}", "a"),
            ("\u{130}", "i\u{307}"),
            ("\u{3392}", "mhz"),
        ]
    )
    func tableB2CaseFolds(_ input: String, _ expected: String) {
        #expect(prepare(input) == expected)
    }

    @Test(
        "The normalization step is NFKC with Unicode 3.2 (RFC 3454 section 4, RFC 3491 section 4).",
        .tags(.idna),
        arguments: [
            ("\u{FF25}\u{FF58}", "ex"),
            ("u\u{308}", "\u{FC}"),
            ("\u{FF76}", "\u{30AB}"),
            ("\u{2460}", "1"),
            ("\u{1100}\u{1161}", "\u{AC00}"),
        ]
    )
    func normalizesToNFKC(_ input: String, _ expected: String) {
        #expect(prepare(input) == expected)
    }

    @Test(
        "Output with a character of tables C.1.2, C.2.2, C.3, C.4, C.5, C.6, C.7, C.8 or C.9 is prohibited (RFC 3491 section 5).",
        .tags(.idna),
        arguments: [
            ("a\u{1680}b", "C.1.2 OGHAM SPACE MARK"),
            ("a\u{06DD}", "C.2.2 ARABIC END OF AYAH"),
            ("a\u{2028}b", "C.2.2 LINE SEPARATOR"),
            ("a\u{E000}", "C.3 private use"),
            ("a\u{FFFD}", "C.6 REPLACEMENT CHARACTER"),
            ("a\u{2FF0}b", "C.7 IDEOGRAPHIC DESCRIPTION CHARACTER LEFT TO RIGHT"),
            ("a\u{200E}b", "C.8 LEFT-TO-RIGHT MARK"),
            ("a\u{202E}b", "C.8 RIGHT-TO-LEFT OVERRIDE"),
            ("a\u{E0001}", "C.9 LANGUAGE TAG"),
        ]
    )
    func prohibitsOutput(_ input: String, _ table: String) {
        #expect(prepare(input) == nil, "\(table)")
    }

    @Test(
        "A non-character code point is prohibited output (RFC 3454 table C.4).",
        .tags(.idna),
        arguments: [UInt32(0xFDD0), 0xFFFE, 0x1FFFF, 0x10FFFF]
    )
    func prohibitsNonCharacters(_ value: UInt32) throws {
        let scalar = try #require(Unicode.Scalar(value))
        #expect(Nameprep.prepare(["a", scalar]) == nil)
    }

    @Test(
        "Prohibition applies to the mapped and normalized output, not the input (RFC 3454 section 5).",
        .tags(.idna)
    )
    func prohibitionChecksOutput() {
        // U+0340 COMBINING GRAVE TONE MARK is in table C.8, but NFKC maps it
        // to U+0300, so the output holds no prohibited character.
        #expect(prepare("a\u{340}") == "\u{E0}")
        // U+3000 IDEOGRAPHIC SPACE is in table C.1.2; NFKC maps it to the
        // ASCII space, which Nameprep allows (ToASCII's STD3 rules reject it).
        #expect(prepare("a\u{3000}b") == "a b")
    }

    @Test(
        "The bidi check of RFC 3454 section 6 rejects mixed directions and RandALCat text that neither starts nor ends with RandALCat.",
        .tags(.idna),
        arguments: [
            ("\u{5D0}\u{5D1}", true),
            ("\u{5D0}1\u{5D1}", true),
            ("\u{627}\u{644}\u{639}\u{631}\u{628}\u{64A}\u{629}", true),
            ("\u{5D0}a", false),
            ("a\u{5D0}b", false),
            ("\u{5D0}1", false),
            ("1\u{5D0}", false),
            ("\u{5D0}\u{5D1}x\u{5D2}", false),
            ("abc", true),
            ("123", true),
        ]
    )
    func checksBidi(_ input: String, _ isAccepted: Bool) {
        #expect((prepare(input) != nil) == isAccepted)
    }

    @Test(
        "Unassigned code points pass, because RFC 3987 section 3.1 sets AllowUnassigned for comparison (RFC 3454 section 7).",
        .tags(.idna)
    )
    func allowsUnassignedCodePoints() {
        // U+0221 LATIN SMALL LETTER D WITH CURL was assigned in Unicode 4.0,
        // so it is in table A.1 for Unicode 3.2.
        #expect(prepare("a\u{221}") == "a\u{221}")
        // U+1E9E LATIN CAPITAL LETTER SHARP S was assigned in Unicode 5.1,
        // after table B.2 was fixed, so it is not folded.
        #expect(prepare("\u{1E9E}") == "\u{1E9E}")
    }

    @Test(
        "Nameprep output never holds a prohibited character, for every single code point.",
        .tags(.idna, .exhaustive)
    )
    func outputIsNeverProhibited() {
        var failures: [UInt32] = []
        for value in UInt32(0)...0x10FFFF {
            guard let scalar = Unicode.Scalar(value), let output = Nameprep.prepare([scalar]) else {
                continue
            }
            if output.contains(where: { Nameprep.isInRanges($0.value, Nameprep.prohibitedRanges) }) {
                failures.append(value)
            }
        }
        #expect(failures.isEmpty)
    }
}
