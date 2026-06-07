import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 8 spoofing considerations")
    struct Section8SpoofingTests {
        @Test("Normalization expectation mismatches preserve exact identity unless a policy selects otherwise.")
        func exactIdentityPreservesNormalizationDifferences() throws {
            let nfc = try IRI(validating: "https://example.com/résumé")
            let decomposed = try IRI(validating: "https://example.com/re\u{301}sume\u{301}")

            #expect(nfc != decomposed)
        }

        @Test("Case differences preserve exact identity unless a scheme or server policy selects otherwise.")
        func exactIdentityPreservesCaseDifferences() throws {
            let mixedCase = try IRI(validating: "https://example.com/PopularPage.html")
            let lowercase = try IRI(validating: "https://example.com/popularpage.html")

            #expect(mixedCase != lowercase)
        }

        @Test("Path-component spoofing policy is separate from generic IRI parsing.")
        func keepsPathSpoofingCandidatesDistinct() throws {
            let latin = try IRI(validating: "https://example.com/admin")
            let cyrillic = try IRI(validating: "https://example.com/\u{0430}dmin")

            #expect(latin != cyrillic)
            #expect(latin.path != cyrillic.path)
        }

        @Test("Domain-name spoofing policy is delegated to IDN/nameprep rules.")
        func keepsDomainSpoofingCandidatesDistinct() throws {
            let latin = try IRI(validating: "https://example.com/")
            let cyrillic = try IRI(validating: "https://ex\u{0430}mple.com/")

            #expect(latin != cyrillic)
            #expect(latin.authority != cyrillic.authority)
        }
    }
}
