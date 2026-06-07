import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 2.2 port syntax")
    struct Section2PortTests {
        @Test(
            "port = *DIGIT",
            arguments: [
                "https://example.com:/",
                "https://example.com:0/",
                "https://example.com:80/",
                "https://example.com:65535/",
            ]
        )
        func acceptsEmptyOrDigitPorts(_ iriString: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }

        @Test(
            "port excludes non-digits.",
            arguments: [
                "https://example.com:a/",
                "https://example.com:8a/",
                "https://example.com:+80/",
                "https://example.com:-80/",
            ]
        )
        func rejectsNonDigitPorts(_ iriString: String) {
            #expect(throws: IRIError.invalidIRI(iriString)) {
                try IRI(validating: iriString)
            }
        }
    }
}
