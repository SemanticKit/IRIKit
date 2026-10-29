@testable import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 5.3.2.2 character normalization keeps every valid IRI valid")
    struct Section5CharacterNormalizationValidityTests {
        /// Where a swept character is placed, and how the characters are
        /// separated so that NFC cannot combine one with the next: every
        /// separator is an ASCII starter that takes part in no composition.
        struct Placement: Sendable, CustomTestStringConvertible {
            let name: String
            let prefix: String
            let separator: String
            let suffix: String
            let allowsPrivate: Bool

            var testDescription: String { name }

            /// The component text between `prefix` and `suffix`, split back
            /// into one entry per swept character.
            func entries(of iri: IRI) -> [String]? {
                let text = Array(iri.rawValue.unicodeScalars)
                guard text.starts(with: prefix.unicodeScalars),
                    text.reversed().starts(with: suffix.unicodeScalars.reversed())
                else {
                    return nil
                }
                let body = text.dropFirst(prefix.unicodeScalars.count)
                    .dropLast(suffix.unicodeScalars.count)
                let separatorScalar = separator.unicodeScalars.first!
                return body.split(separator: separatorScalar, omittingEmptySubsequences: false).map(Self.string)
            }

            static func string(_ scalars: some Sequence<Unicode.Scalar>) -> String {
                var view = String.UnicodeScalarView()
                view.append(contentsOf: scalars)
                return String(view)
            }
        }

        static let placements = [
            Placement(name: "path", prefix: "http://example.org/", separator: "/", suffix: "", allowsPrivate: false),
            Placement(name: "query", prefix: "http://example.org/?", separator: "&", suffix: "", allowsPrivate: true),
            Placement(name: "fragment", prefix: "http://example.org/#", separator: "/", suffix: "", allowsPrivate: false),
            Placement(name: "host", prefix: "http://", separator: ".", suffix: "/", allowsPrivate: false),
            // Not ";": NFC maps U+037E GREEK QUESTION MARK to it.
            Placement(name: "userinfo", prefix: "http://", separator: "!", suffix: "@example.org/", allowsPrivate: false),
        ]

        /// Every `ucschar`, and every `iprivate` where the component allows
        /// it (RFC 3987 section 2.2), except the bidirectional formatting
        /// characters, which RFC 3987 section 4.1 forbids in an IRI.
        static func sweptScalars(allowsPrivate: Bool) -> [Unicode.Scalar] {
            (UInt32(0xA0)...0x10FFFF).compactMap { Unicode.Scalar($0) }.filter {
                (IRIParser.isUCSChar($0) || (allowsPrivate && IRIParser.isIPrivate($0)))
                    && !IRIParser.isBidiFormattingCharacter($0)
            }
        }

        private static func percentDecoded(_ text: String) -> String {
            let scalars = Array(text.unicodeScalars)
            var bytes: [UInt8] = []
            var index = 0
            while index < scalars.count {
                if scalars[index] == "%", index + 2 < scalars.count,
                    let byte = UInt8(Placement.string(scalars[(index + 1)...(index + 2)]), radix: 16)
                {
                    bytes.append(byte)
                    index += 3
                } else {
                    bytes.append(contentsOf: Array(String(scalars[index]).utf8))
                    index += 1
                }
            }
            return String(decoding: bytes, as: UTF8.self)
        }

        private static func nfc(_ text: String) -> String {
            UnicodeNormalizationData.unicode18_0.normalized(text, .nfc)
        }

        @Test(
            "Normalizing with .characters gives a valid, idempotent IRI for every ucschar and iprivate code point, and percent-encodes only what the component cannot hold.",
            .tags(.normalization, .unicodeNormalization),
            arguments: placements
        )
        func everyCodePointStaysValid(_ placement: Placement) throws {
            let swept = Self.sweptScalars(allowsPrivate: placement.allowsPrivate)
            var encoded: [Unicode.Scalar] = []
            let normalizations: [IRINormalization] = [
                .characters,
                [.syntaxBased, .characters],
                [.syntaxBased, .characters, .scheme],
            ]

            for start in stride(from: 0, to: swept.count, by: 512) {
                let chunk = swept[start..<min(start + 512, swept.count)]
                let text = placement.prefix
                    + chunk.map { String($0) }.joined(separator: placement.separator)
                    + placement.suffix
                let iri = try IRI(validating: text)

                for normalization in normalizations {
                    // Normalizing never throws for a valid IRI with a host,
                    // and the normal form is a fixed point.
                    let normalized = try iri.normalized(normalization)
                    #expect(try normalized.normalized(normalization) == normalized)
                }

                let normalized = try iri.normalized(.characters)
                let entries = try #require(placement.entries(of: normalized))
                try #require(entries.count == chunk.count)
                for (scalar, entry) in zip(chunk, entries) {
                    let expected = Self.nfc(String(scalar))
                    // Decoding what normalization encoded gives the NFC form
                    // back: no character is lost or changed.
                    #expect(
                        Self.percentDecoded(entry).unicodeScalars.elementsEqual(expected.unicodeScalars),
                        "U+\(String(scalar.value, radix: 16, uppercase: true)) in the \(placement.name)"
                    )
                    if entry.unicodeScalars.contains("%") {
                        encoded.append(scalar)
                        // Only a character the component cannot hold is
                        // encoded: written literally, the IRI is invalid.
                        let literal = placement.prefix + expected + placement.suffix
                        #expect(throws: IRIError.invalidIRI(literal)) {
                            try IRI(validating: literal)
                        }
                    } else {
                        #expect(entry.unicodeScalars.elementsEqual(expected.unicodeScalars))
                    }
                }
            }

            // U+1FEF GREEK VARIA decomposes to U+0060 GRAVE ACCENT, which no
            // IRI component allows. It is the only such code point.
            #expect(encoded == ["\u{1FEF}"])
        }

        @Test(
            "U+1FEF GREEK VARIA normalizes to %60, whether written literally or percent-encoded.",
            .tags(.normalization, .unicodeNormalization),
            arguments: [
                NormalizationCase("http://example.org/a\u{1FEF}", .characters, expected: "http://example.org/a%60"),
                NormalizationCase("http://example.org/%E1%BF%AF", [.syntaxBased, .characters], expected: "http://example.org/%60"),
                NormalizationCase("http://example.org/?q=\u{1FEF}", [.syntaxBased, .characters], expected: "http://example.org/?q=%60"),
                NormalizationCase("http://example.org/#\u{1FEF}", [.syntaxBased, .characters], expected: "http://example.org/#%60"),
                NormalizationCase("http://\u{1FEF}@example.org/", [.syntaxBased, .characters], expected: "http://%60@example.org/"),
                NormalizationCase("http://a\u{1FEF}.example/", [.syntaxBased, .characters, .scheme], expected: "http://a%60.example/"),
                // The encoded form is a fixed point: %60 is not iunreserved,
                // so percent-encoding normalization keeps it encoded.
                NormalizationCase("http://example.org/a%60", [.syntaxBased, .characters], expected: "http://example.org/a%60"),
            ]
        )
        func greekVariaIsPercentEncoded(_ testCase: NormalizationCase) throws {
            let iri = try IRI(validating: testCase.input)
            let normalized = try iri.normalized(testCase.normalization)

            #expect(normalized.rawValue == testCase.expected)
            #expect(try normalized.normalized(testCase.normalization) == normalized)
        }

        @Test(
            "Two valid IRIs that differ only in how U+1FEF is written compare equal under character normalization.",
            .tags(.normalization, .unicodeNormalization)
        )
        func greekVariaFormsAreEquivalent() throws {
            let literal = try IRI(validating: "http://ex.org/\u{1FEF}")
            let encoded = try IRI(validating: "http://ex.org/%E1%BF%AF")
            let grave = try IRI(validating: "http://ex.org/%60")
            let normalization: IRINormalization = [.syntaxBased, .characters]

            #expect(try literal.isEquivalent(to: encoded, under: normalization))
            #expect(try literal.isEquivalent(to: grave, under: normalization))
            #expect(try literal.isEquivalent(to: grave, under: [.syntaxAndSchemeBased, .characters]))
        }

        @Test(
            "Character normalization keeps percent-encoded triplets whole: a combining mark after a triplet does not compose with its last hex digit.",
            .tags(.normalization, .unicodeNormalization),
            arguments: [
                NormalizationCase("http://example.org/%4E\u{301}", .characters, expected: "http://example.org/%4E\u{301}"),
                NormalizationCase("http://example.org/%4e\u{301}", [.letterCase, .characters], expected: "http://example.org/%4E\u{301}"),
                NormalizationCase("http://example.org/?%4E\u{301}", .characters, expected: "http://example.org/?%4E\u{301}"),
                NormalizationCase("http://example.org/a%2Fe\u{301}", [.syntaxBased, .characters], expected: "http://example.org/a%2F\u{E9}"),
                NormalizationCase("http://example.org/%2F\u{301}\u{327}", .characters, expected: "http://example.org/%2F\u{327}\u{301}"),
                // Percent-encoding normalization decodes %4E to N first, so N
                // and the combining acute accent compose to U+0143.
                NormalizationCase("http://example.org/%4E\u{301}", [.syntaxBased, .characters], expected: "http://example.org/\u{143}"),
            ]
        )
        func tripletsAreNotComposed(_ testCase: NormalizationCase) throws {
            let iri = try IRI(validating: testCase.input)
            let normalized = try iri.normalized(testCase.normalization)

            #expect(normalized.rawValue.unicodeScalars.elementsEqual(testCase.expected.unicodeScalars))
            #expect(try normalized.normalized(testCase.normalization) == normalized)
        }
    }
}
