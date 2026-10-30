import IRIKit
import Testing

extension RFC3987ComplianceTests {
    /// RFC 3987 section 6.5 resolves relative IRI references with the
    /// algorithm of RFC 3986 section 5.2. The examples of RFC 3986
    /// sections 5.4.1 and 5.4.2 are resolved here against
    /// `file:///a/bb/ccc/d;p?q`: the RFC's base `http://a/b/c/d;p?q` with
    /// the `file` scheme, an empty authority and longer segments. The pairs
    /// are those of the W3C Turtle test `IRI-resolution-07` (subjects
    /// `urn:ex:s253` to `urn:ex:s294`), whose expected results are copied
    /// from `IRI-resolution-07.nt`.
    @Suite("Section 6.5 relative reference resolution against a base with an empty authority")
    struct Section6ReferenceResolutionTests {
        static let base = "file:///a/bb/ccc/d;p?q"

        @Test("The base IRI has the file scheme, an empty authority, a path with parameters and a query.")
        func baseParsesWithEmptyAuthority() throws {
            let base = try IRI(validating: Self.base)

            #expect(base.scheme == "file")
            #expect(base.authority == "")
            #expect(base.path == "/a/bb/ccc/d;p")
            #expect(base.query == "q")
            #expect(base.fragment == nil)
        }

        @Test("The base IRI's components assemble into the base IRI and read back unchanged.")
        func baseRoundTripsThroughComponents() throws {
            let base = try IRI(validating: Self.base)
            let components = IRIComponents(
                scheme: base.scheme,
                authority: base.authority,
                path: base.path,
                query: base.query,
                fragment: base.fragment
            )

            #expect(try IRI(components: components).rawValue == Self.base)
        }

        @Test(
            "RFC 3986 section 5.4.1 normal examples resolve to the W3C IRI-resolution-07 results.",
            .tags(.parsing),
            arguments: [
                ("g:h", "g:h"),
                ("g", "file:///a/bb/ccc/g"),
                ("./g", "file:///a/bb/ccc/g"),
                ("g/", "file:///a/bb/ccc/g/"),
                ("/g", "file:///g"),
                ("//g", "file://g"),
                ("?y", "file:///a/bb/ccc/d;p?y"),
                ("g?y", "file:///a/bb/ccc/g?y"),
                ("#s", "file:///a/bb/ccc/d;p?q#s"),
                ("g#s", "file:///a/bb/ccc/g#s"),
                ("g?y#s", "file:///a/bb/ccc/g?y#s"),
                (";x", "file:///a/bb/ccc/;x"),
                ("g;x", "file:///a/bb/ccc/g;x"),
                ("g;x?y#s", "file:///a/bb/ccc/g;x?y#s"),
                ("", "file:///a/bb/ccc/d;p?q"),
                (".", "file:///a/bb/ccc/"),
                ("./", "file:///a/bb/ccc/"),
                ("..", "file:///a/bb/"),
                ("../", "file:///a/bb/"),
                ("../g", "file:///a/bb/g"),
                ("../..", "file:///a/"),
                ("../../", "file:///a/"),
                ("../../g", "file:///a/g"),
            ]
        )
        func normalExamples(_ reference: String, _ expected: String) throws {
            try expectResolution(of: reference, to: expected)
        }

        @Test(
            "RFC 3986 section 5.4.2 abnormal examples resolve to the W3C IRI-resolution-07 results.",
            .tags(.parsing),
            arguments: [
                ("../../../g", "file:///g"),
                ("../../../../g", "file:///g"),
                ("/./g", "file:///g"),
                ("/../g", "file:///g"),
                ("g.", "file:///a/bb/ccc/g."),
                (".g", "file:///a/bb/ccc/.g"),
                ("g..", "file:///a/bb/ccc/g.."),
                ("..g", "file:///a/bb/ccc/..g"),
                ("./../g", "file:///a/bb/g"),
                ("./g/.", "file:///a/bb/ccc/g/"),
                ("g/./h", "file:///a/bb/ccc/g/h"),
                ("g/../h", "file:///a/bb/ccc/h"),
                ("g;x=1/./y", "file:///a/bb/ccc/g;x=1/y"),
                ("g;x=1/../y", "file:///a/bb/ccc/y"),
                ("g?y/./x", "file:///a/bb/ccc/g?y/./x"),
                ("g?y/../x", "file:///a/bb/ccc/g?y/../x"),
                ("g#s/./x", "file:///a/bb/ccc/g#s/./x"),
                ("g#s/../x", "file:///a/bb/ccc/g#s/../x"),
                // A strict parser keeps the scheme of "http:g".
                ("http:g", "http:g"),
            ]
        )
        func abnormalExamples(_ reference: String, _ expected: String) throws {
            try expectResolution(of: reference, to: expected)
        }

        @Test("A delimiter followed by a combining mark still splits the reference, as IRIKit finds delimiters by Unicode scalar.")
        func delimiterBeforeCombiningMark() throws {
            let parts = ReferenceResolver.parts(of: "g?\u{301}#\u{301}")

            #expect(parts.path == "g")
            #expect(parts.query == "\u{301}")
            #expect(parts.fragment == "\u{301}")

            try expectResolution(of: "g#\u{301}", to: "file:///a/bb/ccc/g#\u{301}")
        }

        private func expectResolution(of reference: String, to expected: String) throws {
            let base = try IRI(validating: Self.base)
            let target = try ReferenceResolver.resolve(
                IRIReference(validating: reference),
                against: base
            )

            #expect(target.rawValue == expected)
        }
    }
}
