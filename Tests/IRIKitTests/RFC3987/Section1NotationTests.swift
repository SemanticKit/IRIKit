import Foundation
import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 1.4 notation")
    struct Section1NotationTests {
        @Test("U+ notation in the RFC denotes the actual UCS character in IRI text.")
        func acceptsTheCharacterDenotedByUPlusNotation() throws {
            let iri = try IRI(validating: "https://example.com/\u{044F}")

            #expect(iri.rawValue == "https://example.com/я")
        }

        @Test("XML notation in the RFC denotes the actual UCS character in IRI text.")
        func acceptsTheCharacterDenotedByXMLNotation() throws {
            let iri = try IRI(validating: "https://example.com/\u{044F}")

            #expect(iri.rawValue == "https://example.com/я")
            #expect(URL(iri).absoluteString == "https://example.com/%D1%8F")
        }

        @Test("Octet notation in the RFC is not direct IRI text.")
        func rejectsDocumentationOctetNotationAsIRIText() {
            #expect(throws: IRIError.invalidIRI("https://example.com/<c9>")) {
                try IRI(validating: "https://example.com/<c9>")
            }
        }

        @Test("Bidi notation in the RFC denotes logical-order characters, not presentation order.")
        func storesBidiCharactersInLogicalOrder() throws {
            let iriString = "https://example.com/אבג"
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }
    }
}
