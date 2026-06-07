import Foundation
import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 8 security considerations")
    struct Section8SecurityTests {
        @Test("RFC 3986 security considerations also apply to IRIs.")
        func preservesRFC3986PercentEncodingSecurityBoundaries() throws {
            let encodedDot = try IRI(validating: "https://example.com/%2E%2E/secret")
            let literalDot = try IRI(validating: "https://example.com/../secret")

            #expect(encodedDot != literalDot)
            #expect(URL(encodedDot).absoluteString == "https://example.com/%2E%2E/secret")
        }

        @Test("Visually confusable characters preserve exact identity for comparison.")
        func preservesIdentityForConfusableCharacters() throws {
            let latin = try IRI(validating: "https://example.com/a")
            let cyrillic = try IRI(validating: "https://example.com/\u{0430}")

            #expect(latin != cyrillic)
        }

        @Test("Percent-encoding differences preserve exact identity under simple comparison.")
        func preservesIdentityForPercentEncodingDifferences() throws {
            let characterForm = try IRI(validating: "https://example.com/~user")
            let percentForm = try IRI(validating: "https://example.com/%7Euser")

            #expect(characterForm != percentForm)
        }

        @Test("Display, logging, and storage preserve the original IRI character sequence.")
        func preservesOriginalCharacterSequence() throws {
            let iriString = "https://example.com/résumé.html"
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
            #expect(iri.description == iriString)
        }
    }
}
