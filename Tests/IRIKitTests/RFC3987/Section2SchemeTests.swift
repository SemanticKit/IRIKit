import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 2.2 scheme syntax")
    struct Section2SchemeTests {
        @Test(
            "scheme = ALPHA *( ALPHA / DIGIT / '+' / '-' / '.' )",
            arguments: [
                "a:",
                "x+1:",
                "x-1:",
                "x.1:",
                "HTTP://example.com/",
            ]
        )
        func acceptsSchemeSyntax(_ iriString: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }

        @Test(
            "scheme starts with ALPHA.",
            arguments: [
                "1x:",
                "+x:",
                "-x:",
                ".x:",
                ":path",
            ]
        )
        func rejectsSchemeWithoutLeadingAlpha(_ iriString: String) {
            #expect(throws: IRIError.invalidIRI(iriString)) {
                try IRI(validating: iriString)
            }
        }

        @Test(
            "scheme permits only ALPHA, DIGIT, '+', '-', and '.'.",
            arguments: [
                "ht_tp://example.com/",
                "ht*tp://example.com/",
                "ht tp://example.com/",
            ]
        )
        func rejectsInvalidSchemeCharacters(_ iriString: String) {
            #expect(throws: IRIError.invalidIRI(iriString)) {
                try IRI(validating: iriString)
            }
        }
    }
}
