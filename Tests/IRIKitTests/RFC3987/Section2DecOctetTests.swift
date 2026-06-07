import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 2.2 dec-octet syntax")
    struct Section2DecOctetTests {
        @Test(
            "dec-octet covers 0 through 255 without leading zero multi-digit forms.",
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
            "dec-octet rejects values outside 0 through 255 and leading zero multi-digit forms.",
            arguments: [
                "https://00.0.0.0/",
                "https://01.0.0.0/",
                "https://256.0.0.0/",
                "https://999.0.0.0/",
            ]
        )
        func rejectsInvalidDecOctets(_ iriString: String) {
            #expect(throws: IRIError.invalidIRI(iriString)) {
                try IRI(validating: iriString)
            }
        }
    }
}
