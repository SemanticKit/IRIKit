import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 2.2 path syntax")
    struct Section2PathTests {
        @Test(
            "ihier-part = '//' iauthority ipath-abempty / ipath-absolute / ipath-rootless / ipath-empty",
            arguments: [
                AbsoluteIRICase(
                    iri: "https://example.com",
                    scheme: "https",
                    authority: "example.com",
                    path: "",
                    query: nil,
                    fragment: nil
                ),
                AbsoluteIRICase(
                    iri: "https://example.com/path/segment",
                    scheme: "https",
                    authority: "example.com",
                    path: "/path/segment",
                    query: nil,
                    fragment: nil
                ),
                AbsoluteIRICase(
                    iri: "urn:/absolute/path",
                    scheme: "urn",
                    authority: nil,
                    path: "/absolute/path",
                    query: nil,
                    fragment: nil
                ),
                AbsoluteIRICase(
                    iri: "urn:rootless/path",
                    scheme: "urn",
                    authority: nil,
                    path: "rootless/path",
                    query: nil,
                    fragment: nil
                ),
                AbsoluteIRICase(
                    iri: "urn:",
                    scheme: "urn",
                    authority: nil,
                    path: "",
                    query: nil,
                    fragment: nil
                ),
                AbsoluteIRICase(
                    iri: "urn://",
                    scheme: "urn",
                    authority: "",
                    path: "",
                    query: nil,
                    fragment: nil
                ),
                AbsoluteIRICase(
                    iri: "urn:////path",
                    scheme: "urn",
                    authority: "",
                    path: "//path",
                    query: nil,
                    fragment: nil
                ),
            ]
        )
        func acceptsHierPartPathAlternatives(_ testCase: AbsoluteIRICase) throws {
            let iri = try IRI(validating: testCase.iri)

            #expect(iri.scheme == testCase.scheme)
            #expect(iri.authority == testCase.authority)
            #expect(iri.path == testCase.path)
            #expect(iri.query == testCase.query)
            #expect(iri.fragment == testCase.fragment)
        }

        @Test(
            "When authority is present, ipath-abempty begins with '/' or is empty.",
            arguments: [
                "https://example.com:80path",
            ]
        )
        func rejectsAuthorityPathsThatDoNotBeginWithSlash(_ iriString: String) {
            #expect(throws: IRIError.invalidIRI(iriString)) {
                try IRI(validating: iriString)
            }
        }

        @Test("A leading '//' selects the iauthority branch, whose ihost may be an empty ireg-name.")
        func acceptsEmptyAuthorityBecauseIregNameCanBeEmpty() throws {
            let iri = try IRI(validating: "urn://")

            #expect(iri.authority == "")
            #expect(iri.path == "")
        }

        @Test(
            "ipchar = iunreserved / pct-encoded / sub-delims / ':' / '@'",
            arguments: [
                "urn:alpha-._~",
                "urn:segment:with:colon",
                "urn:segment@with@at",
                "urn:!$&'()*+,;=",
                "urn:%41",
            ]
        )
        func acceptsPathCharacters(_ iriString: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }
    }
}
