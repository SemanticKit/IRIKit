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
    }
}
