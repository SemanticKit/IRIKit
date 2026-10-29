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

        @Test(
            "When authority is absent, ipath-absolute begins with '/' but not '//'.",
            arguments: [
                "//",
                "////path",
            ]
        )
        func rejectsNoAuthorityPathsBeginningWithDoubleSlash(_ path: String) {
            let components = IRIComponents(scheme: "urn", path: path)

            #expect(throws: IRIError.invalidIRI(components.string)) {
                try IRI(components: components)
            }
        }

        @Test(
            "When authority is present, components whose path does not begin with '/' do not assemble into an IRI.",
            arguments: [
                IRIComponents(scheme: "urn", authority: "", path: "a"),
                IRIComponents(scheme: "urn", authority: "h", path: "a"),
                IRIComponents(scheme: "https", authority: "example.com", path: "path"),
            ]
        )
        func rejectsAuthorityComponentsWithPathNotBeginningWithSlash(_ components: IRIComponents) {
            #expect(throws: IRIError.invalidIRI(components.string)) {
                try IRI(components: components)
            }
        }

        @Test(
            "Components that would parse back into different components do not assemble into an IRI.",
            arguments: [
                IRIComponents(scheme: "urn", path: "a?b"),
                IRIComponents(scheme: "urn", path: "a#b"),
                IRIComponents(scheme: "urn", path: "a", query: "b#c"),
                IRIComponents(scheme: "https", authority: "example.com/p", path: "/q"),
                IRIComponents(scheme: "a:b", path: "c"),
                IRIComponents(scheme: "urn", authority: "h?x"),
            ]
        )
        func rejectsComponentsThatDoNotRoundTrip(_ components: IRIComponents) {
            #expect(throws: IRIError.invalidIRI(components.string)) {
                try IRI(components: components)
            }
        }

        @Test(
            "ihier-part components assemble into an IRI that parses back into the same components.",
            arguments: [
                IRIComponents(scheme: "urn", authority: "", path: ""),
                IRIComponents(scheme: "file", authority: "", path: "/etc/hosts"),
                IRIComponents(scheme: "urn", authority: "h", path: "/a"),
                IRIComponents(scheme: "https", authority: "example.com", path: "", query: "q", fragment: "f"),
                IRIComponents(scheme: "urn", path: "/absolute/path"),
                IRIComponents(scheme: "urn", path: "rootless/path"),
                IRIComponents(scheme: "urn", path: ""),
                IRIComponents(scheme: "urn", path: "a", query: "", fragment: ""),
            ]
        )
        func roundTripsComponents(_ components: IRIComponents) throws {
            let iri = try IRI(components: components)

            #expect(iri.rawValue == components.string)
            #expect(iri.scheme == components.scheme)
            #expect(iri.authority == components.authority)
            #expect(iri.path == components.path)
            #expect(iri.query == components.query)
            #expect(iri.fragment == components.fragment)
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
