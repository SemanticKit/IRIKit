@testable import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 5.3.3 IDN host normalization with IDNA ToASCII and Nameprep")
    struct Section5IDNHostNormalizationTests {
        @Test(
            "An RFC 3492 sample label and its ACE form are equivalent, and the normal form is the Nameprep text.",
            .tags(.normalization, .idna),
            arguments: PunycodeSample.rfc3492
        )
        func rfc3492SamplesAreEquivalentToTheirACEForm(_ sample: PunycodeSample) throws {
            let unicode = try IRI(validating: "http://\(sample.unicode).example/")
            let ace = try IRI(validating: "http://xn--\(sample.punycode).example/")
            let normalized = try unicode.normalized(.syntaxAndSchemeBased)

            #expect(try unicode.isEquivalent(to: ace, under: .syntaxAndSchemeBased) == sample.isValidLabel)
            if sample.isValidLabel {
                let lowercased = String(String.UnicodeScalarView(sample.unicode.unicodeScalars.map(IDNA.asciiLowercased)))
                #expect(normalized.rawValue == "http://\(lowercased).example/")
                #expect(try ace.normalized(.syntaxAndSchemeBased) == normalized)
            } else {
                // A label that fails ToASCII makes the host an invalid IDN,
                // which keeps its characters (RFC 3987 section 5.3.3).
                #expect(normalized == unicode)
            }
        }

        @Test(
            "Nameprep table B.2 folds sharp s, so straße and strasse are equivalent hosts (RFC 3491 section 3).",
            .tags(.normalization, .idna),
            arguments: [
                NormalizationCase("http://stra\u{DF}e.example/", .syntaxAndSchemeBased, expected: "http://strasse.example/"),
                NormalizationCase("http://STRA\u{DF}E.example/", .syntaxAndSchemeBased, expected: "http://strasse.example/"),
                NormalizationCase("http://\u{3A3}\u{3BF}\u{3C6}\u{3AF}\u{3B1}\u{3C2}.example/", .syntaxAndSchemeBased, expected: "http://\u{3C3}\u{3BF}\u{3C6}\u{3AF}\u{3B1}\u{3C3}.example/"),
                NormalizationCase("http://b\u{AD}\u{FC}cher.example/", .syntaxAndSchemeBased, expected: "http://b\u{FC}cher.example/"),
                NormalizationCase("http://bu\u{308}cher.example/", .syntaxAndSchemeBased, expected: "http://b\u{FC}cher.example/"),
                NormalizationCase("http://\u{FF58}\u{FF4E}--bcher-kva.example/", .syntaxAndSchemeBased, expected: "http://b\u{FC}cher.example/"),
            ]
        )
        func nameprepMapsHostLabels(_ testCase: NormalizationCase) throws {
            let iri = try IRI(validating: testCase.input)
            let normalized = try iri.normalized(testCase.normalization)

            #expect(normalized.rawValue == testCase.expected)
            #expect(try iri.isEquivalent(to: IRI(validating: testCase.expected), under: testCase.normalization))
            #expect(try normalized.normalized(testCase.normalization) == normalized)
        }

        @Test(
            "A host with a label that Nameprep prohibits or that fails the bidi check is not a valid IDN and keeps its characters.",
            .tags(.normalization, .idna),
            arguments: [
                "http://A\u{1680}B.example/",
                "http://x\u{2FF0}y.Example/",
                "http://\u{5D0}a.example/",
                "http://\u{5D0}1.example/",
                "http://B\u{FC}cher..example/",
                "http://under_score.B\u{FC}cher.example/",
            ]
        )
        func invalidIDNIsKept(_ string: String) throws {
            let iri = try IRI(validating: string)

            #expect(try iri.normalized(.scheme) == iri)
        }

        @Test(
            "A right-to-left label that passes the bidi check is equivalent to its ACE form.",
            .tags(.normalization, .idna)
        )
        func rightToLeftLabel() throws {
            let hebrew = try IRI(validating: "http://\u{5D0}1\u{5D1}.example/")
            let ace = try IRI(validating: "http://xn--1-zhce.example/")

            #expect(try hebrew.isEquivalent(to: ace, under: .syntaxAndSchemeBased))
        }

        /// Labels whose mapping once needed more than one pass, or that sit at
        /// the edges of ToASCII and ToUnicode.
        static let edgeLabels: [String] = [
            "\u{210C}", "\u{1D400}\u{210C}\u{FF22}", "XN--BCHER-KVA", "xn--Bcher-kva",
            "\u{FF58}\u{FF4E}--bcher-kva", "\u{FF38}\u{FF2E}--BCHER-KVA", "xn--a-ecp", "a\u{2488}",
            "xn--rsum-bpad", "R\u{E9}SUM\u{E9}", "stra\u{DF}e", "\u{3392}", "\u{FB01}",
            "\u{130}", "xn--", "xn--a-", "-x", String(repeating: "a", count: 63),
            String(repeating: "a", count: 55) + "\u{FC}", String(repeating: "\u{FC}", count: 59),
        ] + PunycodeSample.rfc3492.flatMap { [$0.unicode, "xn--" + $0.punycode] }

        /// Checks the three properties that make the label mapping a fixed
        /// point without iteration and make equal normal forms mean the
        /// RFC 3490 section 3.1 requirement 4 label match:
        ///
        /// 1. normal(normal(x)) == normal(x);
        /// 2. ToASCII(normal(x)) equals ToASCII(x) ignoring ASCII case;
        /// 3. normal(x) == normal(lowercased ToASCII(x)), so the normal form
        ///    depends only on the case-folded ToASCII result.
        ///
        /// With 2 and 3, normal(x) == normal(y) exactly when ToASCII(x) and
        /// ToASCII(y) are equal ignoring case.
        static func labelMappingViolation(_ label: [Unicode.Scalar]) -> String? {
            let lowered = { (scalars: [Unicode.Scalar]) in scalars.map(IDNA.asciiLowercased) }
            guard let ascii = IDNA.toASCII(label) else {
                return IRINormalizer.domainLabelNormalized(label) == nil ? nil : "maps a label that fails ToASCII"
            }
            guard let normal = IRINormalizer.domainLabelNormalized(label) else {
                return "fails a label that passes ToASCII"
            }
            guard IRINormalizer.domainLabelNormalized(normal) == normal else {
                return "is not idempotent"
            }
            guard let normalASCII = IDNA.toASCII(normal), lowered(normalASCII) == lowered(ascii) else {
                return "changes the ToASCII result"
            }
            guard IRINormalizer.domainLabelNormalized(lowered(ascii)) == normal else {
                return "depends on more than the ToASCII result"
            }
            return nil
        }

        @Test(
            "The label mapping is a fixed point with no pass bound, and equal normal forms are exactly the RFC 3490 label match (edge labels).",
            .tags(.normalization, .idna),
            arguments: edgeLabels
        )
        func labelMappingPropertiesForEdgeLabels(_ label: String) {
            #expect(Self.labelMappingViolation(Array(label.unicodeScalars)) == nil)
        }

        /// The planes in which Unicode 3.2, the version Nameprep fixes,
        /// assigns characters. Every other code point is unassigned in
        /// Unicode 3.2 (so Nameprep passes it unchanged under
        /// AllowUnassigned) or private use (so table C.3 prohibits it).
        static let unicode3_2Planes: [UInt32] = [0x0, 0x1, 0x2, 0xE]

        @Test(
            "The label mapping is a fixed point with no pass bound, and equal normal forms are exactly the RFC 3490 label match (every code point of the Unicode 3.2 planes, alone and between ASCII letters).",
            .tags(.normalization, .idna),
            arguments: unicode3_2Planes.flatMap { plane in stride(from: plane << 16, to: (plane + 1) << 16, by: 0x4000) }
        )
        func labelMappingPropertiesForEveryCodePoint(_ start: UInt32) {
            var failures: [String] = []
            for value in start..<(start + 0x4000) {
                guard let scalar = Unicode.Scalar(value) else {
                    continue
                }
                for label in [[scalar], ["a", scalar, "B"]] {
                    if let violation = Self.labelMappingViolation(label) {
                        failures.append("U+\(String(value, radix: 16, uppercase: true)) \(violation)")
                    }
                }
            }
            #expect(failures.isEmpty, "\(failures.prefix(20))")
        }

        @Test(
            "The label mapping is a fixed point for a sample of the code points that Unicode 3.2 leaves unassigned or private use.",
            .tags(.normalization, .idna),
            arguments: [UInt32(0x3), 0x4, 0x7, 0xA, 0xD, 0xF, 0x10]
        )
        func labelMappingPropertiesOutsideTheUnicode3_2Planes(_ plane: UInt32) {
            var failures: [String] = []
            for value in stride(from: plane << 16, to: (plane + 1) << 16, by: 61) {
                let scalar = Unicode.Scalar(value)!
                for label in [[scalar], ["a", scalar, "B"]] {
                    if let violation = Self.labelMappingViolation(label) {
                        failures.append("U+\(String(value, radix: 16, uppercase: true)) \(violation)")
                    }
                }
            }
            #expect(failures.isEmpty, "\(failures.prefix(20))")
        }
    }
}
