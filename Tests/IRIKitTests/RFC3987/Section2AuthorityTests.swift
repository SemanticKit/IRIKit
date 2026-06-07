import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 2.2 authority syntax")
    struct Section2AuthorityTests {
        @Test(
            "iauthority = [ iuserinfo '@' ] ihost [ ':' port ]",
            arguments: [
                AbsoluteIRICase(
                    iri: "https://user:pass@example.com:8080/path",
                    scheme: "https",
                    authority: "user:pass@example.com:8080",
                    path: "/path",
                    query: nil,
                    fragment: nil
                ),
                AbsoluteIRICase(
                    iri: "https://[2001:db8::7]/path",
                    scheme: "https",
                    authority: "[2001:db8::7]",
                    path: "/path",
                    query: nil,
                    fragment: nil
                ),
                AbsoluteIRICase(
                    iri: "https://[v7.aB:]/path",
                    scheme: "https",
                    authority: "[v7.aB:]",
                    path: "/path",
                    query: nil,
                    fragment: nil
                ),
                AbsoluteIRICase(
                    iri: "https://192.168.0.1/path",
                    scheme: "https",
                    authority: "192.168.0.1",
                    path: "/path",
                    query: nil,
                    fragment: nil
                ),
                AbsoluteIRICase(
                    iri: "https://例え.テスト/path",
                    scheme: "https",
                    authority: "例え.テスト",
                    path: "/path",
                    query: nil,
                    fragment: nil
                ),
            ]
        )
        func acceptsAuthorityAlternatives(_ testCase: AbsoluteIRICase) throws {
            let iri = try IRI(validating: testCase.iri)

            #expect(iri.scheme == testCase.scheme)
            #expect(iri.authority == testCase.authority)
            #expect(iri.path == testCase.path)
            #expect(iri.query == testCase.query)
            #expect(iri.fragment == testCase.fragment)
        }

        @Test(
            "IP-literal = '[' ( IPv6address / IPvFuture ) ']'",
            arguments: [
                "https://[2001:db8::7/path",
                "https://2001:db8::7]/path",
                "https://[v.x]/path",
                "https://[v7.]/path",
                "https://[fe80::1%25en0]/path",
            ]
        )
        func rejectsInvalidIPLiteralAuthorities(_ iri: String) {
            #expect(throws: IRIError.invalidIRI(iri)) {
                try IRI(validating: iri)
            }
        }

        @Test(
            "IPv4address = dec-octet '.' dec-octet '.' dec-octet '.' dec-octet",
            arguments: [
                "https://256.0.0.1/path",
                "https://192.168.0/path",
                "https://192.168.0.1.2/path",
                "https://01.2.3.4/path",
            ]
        )
        func rejectsInvalidIPv4Authorities(_ iri: String) {
            #expect(throws: IRIError.invalidIRI(iri)) {
                try IRI(validating: iri)
            }
        }

        @Test(
            "port = *DIGIT",
            arguments: [
                "https://example.com:port/path",
                "https://example.com:80x/path",
            ]
        )
        func rejectsNonDigitPorts(_ iri: String) {
            #expect(throws: IRIError.invalidIRI(iri)) {
                try IRI(validating: iri)
            }
        }
    }
}
