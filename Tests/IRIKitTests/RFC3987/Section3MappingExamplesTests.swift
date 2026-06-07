import Foundation
import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 3.1 IRI to URI mapping examples")
    struct Section3MappingExamplesTests {
        @Test("The RFC red rose example preserves existing percent-encoding and the fragment delimiter.")
        func mapsRedRoseExample() throws {
            let iri = try IRI(validating: "http://www.example.org/red%09rosé#red")

            #expect(URL(iri).absoluteString == "http://www.example.org/red%09ros%C3%A9#red")
        }

        @Test("The RFC non-BMP Old Italic example maps each scalar through UTF-8 percent-encoding.")
        func mapsOldItalicExample() throws {
            let iri = try IRI(validating: "http://example.com/\u{10300}\u{10301}\u{10302}")

            #expect(URL(iri).absoluteString == "http://example.com/%F0%90%8C%80%F0%90%8C%81%F0%90%8C%82")
        }

        @Test("IRI-to-URI mapping is idempotent for URI-form references.")
        func mappingURIFormReferencesIsIdempotent() throws {
            let reference = try IRIReference(validating: "http://www.example.org/red%09ros%C3%A9#red")

            #expect(URL(reference).absoluteString == reference.rawValue)
        }

        @Test("Every URI is by definition an IRI.")
        func acceptsURIAsIRI() throws {
            let iri = try IRI(validating: "https://example.com/path?query#fragment")

            #expect(URL(iri).absoluteString == iri.rawValue)
        }
    }
}
