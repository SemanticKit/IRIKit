import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 4 bidirectional IRIs")
    struct Section4BidiTests {
        @Test(
            "Bidirectional IRIs MUST be in full logical order and conform to IRI syntax.",
            arguments: [
                "https://example.com/שלום/123",
                "https://مثال.إختبار/مسار",
            ]
        )
        func storesBidiIRIsInLogicalOrder(_ iriString: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }

        @Test(
            "IRIs MUST NOT contain bidirectional formatting characters.",
            arguments: [
                "https://example.com/\u{200E}",
                "https://example.com/\u{200F}",
                "https://example.com/\u{202A}",
                "https://example.com/\u{202B}",
                "https://example.com/\u{202D}",
                "https://example.com/\u{202E}",
                "https://example.com/\u{202C}",
            ]
        )
        func rejectsBidiFormattingCharacters(_ iriString: String) {
            #expect(throws: IRIError.invalidIRI(iriString)) {
                try IRI(validating: iriString)
            }
        }

        @Test("Bidi components SHOULD NOT mix right-to-left and left-to-right characters.")
        func preservesMixedDirectionComponentsForPolicyEvaluation() throws {
            let iri = try IRI(validating: "https://example.com/abcשלום")

            #expect(iri.path == "/abcשלום")
        }

        @Test("Bidi components using right-to-left characters SHOULD start and end right-to-left.")
        func preservesRTLComponentBoundaryCharacters() throws {
            let iri = try IRI(validating: "https://example.com/שלום")

            #expect(iri.path.hasSuffix("ם"))
        }
    }
}
