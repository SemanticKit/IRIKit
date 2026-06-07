import Foundation
import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 3.1 IRI to URI preprocessing")
    struct Section3IRIToURIPreprocessingTests {
        @Test("Paper, spoken, or encoding-independent IRI input is normalized to NFC before URI mapping.")
        func mapsPreparedNFCInputToURI() throws {
            let iri = try IRI(validating: "https://example.com/résumé")

            #expect(URL(iri).absoluteString == "https://example.com/r%C3%A9sum%C3%A9")
        }

        @Test("Known non-Unicode encoded IRI input is converted to UCS normalized to NFC before URI mapping.")
        func mapsKnownCharacterInputAfterItIsRepresentedAsUnicode() throws {
            let iri = try IRI(validating: "https://example.com/é")

            #expect(URL(iri).absoluteString == "https://example.com/%C3%A9")
        }

        @Test("Unicode-based IRI input is not normalized before URI mapping.")
        func mapsUnicodeInputWithoutNormalization() throws {
            let iri = try IRI(validating: "https://example.com/e\u{301}")

            #expect(URL(iri).absoluteString == "https://example.com/e%CC%81")
        }

        @Test("Printable US-ASCII characters outside URI syntax require explicit preprocessing or conversion failure.")
        func rejectsPrintableASCIIOutsideIRISyntax() {
            #expect(throws: IRIError.invalidIRI("https://example.com/path with space")) {
                try IRI(validating: "https://example.com/path with space")
            }
        }
    }
}
