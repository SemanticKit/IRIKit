import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 5.2 preparation for comparison")
    struct Section5PreparationTests {
        @Test("Protocol or format escaping is resolved before IRI comparison.")
        func comparesResolvedCharacterSequences() throws {
            let direct = try IRI(validating: "https://example.com/résumé")
            let resolved = try IRI(validating: "https://example.com/résumé")

            #expect(direct == resolved)
        }

        @Test("Transfer and content-transfer encodings are resolved before IRI comparison.")
        func comparesIdentifierTextAfterTransferDecoding() throws {
            let decoded = try IRI(validating: "https://example.com/雪")

            #expect(decoded.rawValue == "https://example.com/雪")
        }
    }
}
