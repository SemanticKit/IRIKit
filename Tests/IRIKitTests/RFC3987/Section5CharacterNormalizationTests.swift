import Foundation
import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 5.3.2.2 character normalization")
    struct Section5CharacterNormalizationTests {
        @Test("Creators should use NFC for newly created IRIs.")
        func exactIdentityPreservesCreatorNormalizationChoice() throws {
            let nfc = try IRI(validating: "http://www.example.org/résumé.html")
            let decomposed = try IRI(validating: "http://www.example.org/re\u{301}sume\u{301}.html")

            #expect(nfc != decomposed)
        }

        @Test("Arbitrary third-party Unicode normalization is not allowed for comparison.")
        func simpleComparisonDoesNotApplyUnicodeNormalization() throws {
            let nfc = try IRI(validating: "http://www.example.org/résumé.html")
            let decomposed = try IRI(validating: "http://www.example.org/re\u{301}sume\u{301}.html")

            #expect(nfc != decomposed)
        }

        @Test("Unicode-input IRI-to-URI mapping does not normalize before percent-encoding.")
        func mapsDecomposedUnicodeWithoutNormalization() throws {
            let iri = try IRI(validating: "http://www.example.org/re\u{301}sume\u{301}.html")

            #expect(URL(iri).absoluteString == "http://www.example.org/re%CC%81sume%CC%81.html")
        }

        @Test(
            "Syntax-based normalization does not apply Unicode character normalization.",
            .tags(.normalization)
        )
        func syntaxBasedNormalizationKeepsCharacterForm() throws {
            let nfc = try IRI(validating: "http://www.example.org/résumé.html")
            let decomposed = try IRI(validating: "http://www.example.org/re\u{301}sume\u{301}.html")

            #expect(try !nfc.isEquivalent(to: decomposed))
            #expect(try !nfc.isEquivalent(to: decomposed, under: .syntaxAndSchemeBased))
        }

        @Test(
            "Character normalization maps text to NFC when the caller opts in for transcoded input.",
            .tags(.normalization)
        )
        func characterNormalizationUsesNFC() throws {
            let decomposed = try IRI(validating: "http://www.example.org/re\u{301}sume\u{301}.html?q=e\u{301}#e\u{301}")
            let normalized = try decomposed.normalized(.characters)

            #expect(normalized.rawValue.unicodeScalars.elementsEqual("http://www.example.org/r\u{E9}sum\u{E9}.html?q=\u{E9}#\u{E9}".unicodeScalars))
            #expect(try decomposed.isEquivalent(
                to: IRI(validating: "http://www.example.org/résumé.html?q=é#é"),
                under: [.syntaxBased, .characters]
            ))
        }

        @Test(
            "Character normalization uses NFC, not NFKC, outside IDN host labels.",
            .tags(.normalization)
        )
        func characterNormalizationDoesNotApplyCompatibilityMapping() throws {
            let fullWidth = try IRI(validating: "http://example.org/\u{FF41}")

            #expect(try fullWidth.normalized(.characters).rawValue == "http://example.org/\u{FF41}")
        }
    }
}
