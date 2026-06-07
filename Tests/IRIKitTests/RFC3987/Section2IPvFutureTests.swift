import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 2.2 IPvFuture syntax")
    struct Section2IPvFutureTests {
        @Test(
            "IPvFuture = 'v' 1*HEXDIG '.' 1*( unreserved / sub-delims / ':' )",
            arguments: [
                "https://[v1.a]/",
                "https://[vF.alpha:beta]/",
                "https://[v7.!$&'()*+,;=:]/",
            ]
        )
        func acceptsIPvFutureSyntax(_ iriString: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }

        @Test(
            "IPvFuture requires at least one version hex digit.",
            arguments: [
                "https://[v.alpha]/",
                "https://[v.]/",
            ]
        )
        func rejectsIPvFutureWithoutVersionDigits(_ iriString: String) {
            #expect(throws: IRIError.invalidIRI(iriString)) {
                try IRI(validating: iriString)
            }
        }

        @Test(
            "IPvFuture address text excludes gen-delims other than ':'.",
            arguments: [
                "https://[v1.a/b]/",
                "https://[v1.a?b]/",
                "https://[v1.a#b]/",
                "https://[v1.a[b]/",
                "https://[v1.a]b]/",
                "https://[v1.a@b]/",
            ]
        )
        func rejectsIPvFutureAddressGenDelimiters(_ iriString: String) {
            #expect(throws: IRIError.invalidIRI(iriString)) {
                try IRI(validating: iriString)
            }
        }
    }
}
