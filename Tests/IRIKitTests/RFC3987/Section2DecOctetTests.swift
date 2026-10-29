import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 2.2 dec-octet syntax")
    struct Section2DecOctetTests {
        @Test(
            "dec-octet covers 0 through 255 without leading zero multi-digit forms.",
            .tags(.parsing),
            arguments: [
                "https://0.0.0.0/",
                "https://9.9.9.9/",
                "https://10.99.100.199/",
                "https://200.249.250.255/",
            ]
        )
        func acceptsValidDecOctets(_ iriString: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }

        @Test(
            "A host with a value outside dec-octet is not an IPv4address, so it is an ireg-name (RFC 3986 section 3.2.2).",
            .tags(.parsing),
            arguments: [
                "https://00.0.0.0/",
                "https://01.0.0.0/",
                "https://256.0.0.0/",
                "https://999.0.0.0/",
            ]
        )
        func readsInvalidDecOctetsAsRegisteredNames(_ iriString: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }
    }
}
