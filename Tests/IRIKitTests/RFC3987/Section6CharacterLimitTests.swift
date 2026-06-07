import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 6.1 UCS character limitations")
    struct Section6CharacterLimitTests {
        @Test("Generic IRI software cannot check every scheme-specific character limitation.")
        func genericSyntaxPreservesSchemeSpecificCharacters() throws {
            let iri = try IRI(validating: "custom:résumé")

            #expect(iri.scheme == "custom")
            #expect(iri.path == "résumé")
        }

        @Test("Visually confusable characters remain distinct in exact IRI identity.")
        func keepsVisuallyConfusableCharactersDistinct() throws {
            let latinA = try IRI(validating: "https://example.com/A")
            let greekAlpha = try IRI(validating: "https://example.com/\u{0391}")
            let cyrillicA = try IRI(validating: "https://example.com/\u{0410}")

            #expect(latinA != greekAlpha)
            #expect(greekAlpha != cyrillicA)
            #expect(latinA != cyrillicA)
        }

        @Test("Newly created resource names should prefer normalized compatibility-safe characters.")
        func preservesNormalizationDifferencesForCreationPolicyBoundaries() throws {
            let nfc = try IRI(validating: "https://example.com/résumé")
            let decomposed = try IRI(validating: "https://example.com/re\u{301}sume\u{301}")

            #expect(nfc != decomposed)
        }
    }
}
