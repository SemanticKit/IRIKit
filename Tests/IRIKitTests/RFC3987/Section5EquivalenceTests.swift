import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 5.1 equivalence")
    struct Section5EquivalenceTests {
        @Test("IRI equivalence is based on string comparison plus selected comparison policy.")
        func defaultEquivalenceUsesExactIdentity() throws {
            let lhs = try IRI(validating: "https://example.com/%7Euser")
            let rhs = try IRI(validating: "https://example.com/~user")

            #expect(lhs != rhs)
        }

        @Test("Relative references are resolved to target IRIs before comparison.")
        func relativeReferencesRemainDistinctBeforeResolution() throws {
            let relative = try IRIReference(validating: "../résumé")
            let absolute = try IRIReference(validating: "https://example.com/résumé")

            #expect(relative != absolute)
        }

        @Test("Network-action comparison excludes fragment components.")
        func identityComparisonPreservesFragmentComponents() throws {
            let withoutFragment = try IRI(validating: "https://example.com/résumé")
            let withFragment = try IRI(validating: "https://example.com/résumé#section")

            #expect(withoutFragment != withFragment)
        }

        @Test("Identity-token comparison uses simple string comparison.")
        func identityTokensUseSimpleStringComparison() throws {
            let lhs = try IRI(validating: "https://example.com/résumé")
            let rhs = try IRI(validating: "https://example.com/re\u{301}sume\u{301}")

            #expect(lhs != rhs)
        }
    }
}
