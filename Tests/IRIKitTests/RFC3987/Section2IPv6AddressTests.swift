import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 2.2 IPv6 address syntax")
    struct Section2IPv6AddressTests {
        @Test(
            "IPv6address alternatives accept compressed and uncompressed forms.",
            arguments: [
                "https://[2001:0db8:0000:0000:0000:ff00:0042:8329]/",
                "https://[2001:db8::ff00:42:8329]/",
                "https://[::1]/",
                "https://[::]/",
                "https://[2001:db8::]/",
                "https://[::ffff:192.0.2.128]/",
            ]
        )
        func acceptsIPv6AddressAlternatives(_ iriString: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }

        @Test(
            "h16 = 1*4HEXDIG",
            arguments: [
                "https://[20010:db8::1]/",
                "https://[2001:db8:00000::1]/",
            ]
        )
        func rejectsIPv6PiecesLongerThanFourHexDigits(_ iriString: String) {
            #expect(throws: IRIError.invalidIRI(iriString)) {
                try IRI(validating: iriString)
            }
        }

        @Test(
            "IPv6address allows only one '::' compression marker.",
            arguments: [
                "https://[2001::db8::1]/",
                "https://[::ffff::192.0.2.128]/",
            ]
        )
        func rejectsMultipleIPv6CompressionMarkers(_ iriString: String) {
            #expect(throws: IRIError.invalidIRI(iriString)) {
                try IRI(validating: iriString)
            }
        }

        @Test(
            "ls32 = ( h16 ':' h16 ) / IPv4address",
            arguments: [
                "https://[2001:db8::192.0.2.128]/",
                "https://[2001:db8::c000:0280]/",
            ]
        )
        func acceptsIPv6LS32Alternatives(_ iriString: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }
    }
}
