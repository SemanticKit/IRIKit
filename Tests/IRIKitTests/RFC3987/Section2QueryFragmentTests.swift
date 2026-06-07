import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 2.2 query and fragment syntax")
    struct Section2QueryFragmentTests {
        @Test(
            "iquery = *( ipchar / iprivate / '/' / '?' )",
            arguments: [
                "https://example.com/path?name=renée",
                "https://example.com/path?/allowed/and?allowed",
                "https://example.com/path?\u{E000}",
            ]
        )
        func acceptsQueryCharacters(_ iriString: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }

        @Test(
            "ifragment = *( ipchar / '/' / '?' )",
            arguments: [
                "https://example.com/path#section",
                "https://example.com/path#/allowed/and?allowed",
                "https://example.com/path#renée",
            ]
        )
        func acceptsFragmentCharacters(_ iriString: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }

        @Test(
            "ifragment does not include iprivate.",
            arguments: [
                "https://example.com/path#\u{E000}",
                "https://example.com/path#\u{F0000}",
            ]
        )
        func rejectsPrivateCharactersInFragment(_ iriString: String) {
            #expect(throws: IRIError.invalidIRI(iriString)) {
                try IRI(validating: iriString)
            }
        }

        @Test(
            "Multiple '?' characters belong to query or fragment content after the first delimiter.",
            arguments: [
                "https://example.com/path?first?second",
                "https://example.com/path#first?second",
            ]
        )
        func acceptsRepeatedQuestionMarksInQueryAndFragment(_ iriString: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }
    }
}
