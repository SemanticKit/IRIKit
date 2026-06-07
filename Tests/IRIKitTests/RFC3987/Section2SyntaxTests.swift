import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 2.2 IRI syntax")
    struct Section2IRISyntaxTests {
        @Test(
            "IRI = scheme ':' ihier-part [ '?' iquery ] [ '#' ifragment ]",
            arguments: [
                AbsoluteIRICase(
                    iri: "https://example.com/path/to/resource?name=renée#section",
                    scheme: "https",
                    authority: "example.com",
                    path: "/path/to/resource",
                    query: "name=renée",
                    fragment: "section"
                ),
                AbsoluteIRICase(
                    iri: "urn:example:animal:ferret:nose",
                    scheme: "urn",
                    authority: nil,
                    path: "example:animal:ferret:nose",
                    query: nil,
                    fragment: nil
                ),
                AbsoluteIRICase(
                    iri: "about:blank",
                    scheme: "about",
                    authority: nil,
                    path: "blank",
                    query: nil,
                    fragment: nil
                ),
            ]
        )
        func acceptsAbsoluteIRIs(_ testCase: AbsoluteIRICase) throws {
            let iri = try IRI(validating: testCase.iri)

            #expect(iri.scheme == testCase.scheme)
            #expect(iri.authority == testCase.authority)
            #expect(iri.path == testCase.path)
            #expect(iri.query == testCase.query)
            #expect(iri.fragment == testCase.fragment)
        }

        @Test(
            "scheme = ALPHA *( ALPHA / DIGIT / '+' / '-' / '.' )",
            arguments: [
                "example.com/path",
                "1https://example.com",
            ]
        )
        func rejectsInvalidAbsoluteIRIs(_ iri: String) {
            #expect(throws: IRIError.invalidIRI(iri)) {
                try IRI(validating: iri)
            }
        }

        @Test(
            "pct-encoded = '%' HEXDIG HEXDIG",
            arguments: [
                "https://example.com/%E",
                "https://example.com/%ZZ",
            ]
        )
        func rejectsInvalidPercentEncoding(_ iri: String) {
            #expect(throws: IRIError.invalidIRI(iri)) {
                try IRI(validating: iri)
            }
        }
    }

    @Suite("Section 2.2 IRI-reference syntax")
    struct Section2IRIReferenceSyntaxTests {
        @Test(
            "IRI-reference = IRI / irelative-ref",
            arguments: [
                "https://example.com/rosé?tag=雪#frag",
                "//example.com/path",
                "/path/to/resource",
                "path/to/resource",
                "?q=雪",
                "#section",
                "",
            ]
        )
        func acceptsIRIReferences(_ referenceString: String) throws {
            let reference = try IRIReference(validating: referenceString)

            #expect(reference.rawValue == referenceString)
        }

        @Test(
            "IRI references are sequences of characters accepted by the section 2.2 grammar.",
            arguments: [
                "path with space",
                "%E",
            ]
        )
        func rejectsInvalidIRIReferences(_ referenceString: String) {
            #expect(throws: IRIError.invalidIRIReference(referenceString)) {
                try IRIReference(validating: referenceString)
            }
        }
    }
}
