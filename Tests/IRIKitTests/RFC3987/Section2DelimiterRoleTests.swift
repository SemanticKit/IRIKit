import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 2.1 and 2.2 delimiter roles")
    struct Section2DelimiterRoleTests {
        @Test("UCS characters outside US-ASCII are not reserved delimiters.")
        func treatsNonASCIICharactersAsDataNotDelimiters() throws {
            let iri = try IRI(validating: "https://example.com/雪/path")

            #expect(iri.path == "/雪/path")
        }

        @Test(
            "gen-delims are delimiters by component position, not globally valid data characters.",
            arguments: [
                "https://example.com/path[",
                "https://example.com/path]",
                "https://example.com/path#fragment#extra",
            ]
        )
        func rejectsGeneralDelimitersInInvalidComponentPositions(_ iriString: String) {
            #expect(throws: IRIError.invalidIRI(iriString)) {
                try IRI(validating: iriString)
            }
        }

        @Test(
            "sub-delims are valid where the selected component production includes them.",
            arguments: [
                "urn:!",
                "urn:$",
                "urn:&",
                "urn:'",
                "urn:(",
                "urn:)",
                "urn:*",
                "urn:+",
                "urn:,",
                "urn:;",
                "urn:=",
            ]
        )
        func acceptsEachSubDelimiterInPath(_ iriString: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }
    }
}
