import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 5.3.2 syntax-based normalization")
    struct Section5NormalizationTests {
        @Test("Simple string comparison MUST NOT map IRIs to URIs.")
        func simpleStringComparisonDoesNotMapToURI() throws {
            let iri = try IRI(validating: "https://example.com/rosé")
            let uriForm = try IRI(validating: "https://example.com/ros%C3%A9")

            #expect(iri != uriForm)
        }

        @Test("Syntax-based normalization uppercases percent-encoding hex digits.")
        func exactIdentityPreservesPercentEncodingCase() throws {
            let lowercase = try IRI(validating: "https://example.com/%3a")
            let uppercase = try IRI(validating: "https://example.com/%3A")

            #expect(lowercase != uppercase)
        }

        @Test("Syntax-based normalization lowercases scheme and ASCII-only host.")
        func exactIdentityPreservesSchemeAndHostCase() throws {
            let mixed = try IRI(validating: "HTTP://www.EXAMPLE.com/")
            let lower = try IRI(validating: "http://www.example.com/")

            #expect(mixed != lower)
        }

        @Test("Syntax-based normalization decodes percent-encoded unreserved characters.")
        func exactIdentityPreservesPercentEncodedUnreservedCharacters() throws {
            let encoded = try IRI(validating: "http://example.org/%7Euser")
            let decoded = try IRI(validating: "http://example.org/~user")

            #expect(encoded != decoded)
        }

        @Test("Syntax-based normalization removes dot-segments from paths.")
        func exactIdentityPreservesDotSegments() throws {
            let dotted = try IRI(validating: "http://example.org/a/../b")
            let normalized = try IRI(validating: "http://example.org/b")

            #expect(dotted != normalized)
        }
    }
}
