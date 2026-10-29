import IRIKit
import Testing

extension RFC3987ComplianceTests {
    /// RFC 3987 section 2 defines a character as a Unicode code point, so
    /// the grammar finds delimiters among code points. A combining mark after
    /// a delimiter is a separate character and never hides the delimiter.
    @Suite("Section 2.2 delimiters are found among code points")
    struct Section2CodePointDelimiterTests {
        struct ComponentCase: Sendable, CustomTestStringConvertible {
            let input: String
            let authority: String?
            let path: String
            let query: String?
            let fragment: String?

            var testDescription: String {
                input.unicodeScalars.map { $0.isASCII ? String($0) : "U+\(String($0.value, radix: 16, uppercase: true))" }
                    .joined()
            }
        }

        @Test(
            "A combining mark after //, /, ?, # or @ does not join with the delimiter.",
            arguments: [
                ComponentCase(
                    input: "http://\u{301}example.org/", authority: "\u{301}example.org", path: "/", query: nil, fragment: nil
                ),
                ComponentCase(
                    input: "http://user@\u{301}example.org/", authority: "user@\u{301}example.org", path: "/", query: nil,
                    fragment: nil
                ),
                ComponentCase(
                    input: "http://example.org/\u{301}a/\u{301}", authority: "example.org", path: "/\u{301}a/\u{301}", query: nil,
                    fragment: nil
                ),
                ComponentCase(
                    input: "http://example.org/a?\u{301}q#\u{301}f", authority: "example.org", path: "/a", query: "\u{301}q",
                    fragment: "\u{301}f"
                ),
                ComponentCase(
                    input: "foo:/\u{301}//a", authority: nil, path: "/\u{301}//a", query: nil, fragment: nil
                ),
            ]
        )
        func combiningMarkAfterDelimiter(_ testCase: ComponentCase) throws {
            let iri = try IRI(validating: testCase.input)

            #expect(iri.authority?.unicodeScalars.elementsEqual(testCase.authority?.unicodeScalars ?? "".unicodeScalars) ?? (testCase.authority == nil))
            #expect(iri.path.unicodeScalars.elementsEqual(testCase.path.unicodeScalars))
            #expect(iri.query.map { Array($0.unicodeScalars) } == testCase.query.map { Array($0.unicodeScalars) })
            #expect(iri.fragment.map { Array($0.unicodeScalars) } == testCase.fragment.map { Array($0.unicodeScalars) })
        }

        @Test(
            "Scheme-based normalization finds the host after // and @ when a combining mark follows them.",
            .tags(.normalization)
        )
        func schemeNormalizationFindsHost() throws {
            let plain = try IRI(validating: "http://\u{301}example.org")
            let withUser = try IRI(validating: "http://user@\u{301}example.org:80")

            #expect(try plain.normalized(.syntaxAndSchemeBased).authority != nil)
            #expect(try plain.normalized(.syntaxAndSchemeBased).path == "/")
            #expect(try withUser.normalized(.syntaxAndSchemeBased).authority?.unicodeScalars.starts(with: "user@\u{301}".unicodeScalars) == true)
            #expect(try withUser.normalized(.syntaxAndSchemeBased).authority?.unicodeScalars.contains(":") == false)
        }

        @Test(
            "A combining mark after the port delimiter is not a port digit.",
            arguments: [
                "http://example.org:\u{301}/",
                "http://example.org:80\u{301}/",
                "http://[::1]:\u{301}/",
            ]
        )
        func combiningMarkInPortIsRejected(_ iriString: String) {
            #expect(throws: IRIError.invalidIRI(iriString)) {
                try IRI(validating: iriString)
            }
        }

        @Test(
            "DIGIT and HEXDIG are US-ASCII (RFC 5234 appendix B.1), so other digits are not port digits or percent-encoding digits.",
            arguments: [
                "http://example.org:\u{661}\u{662}/",
                "http://example.org:\u{FF18}\u{FF10}/",
                "http://example.org/%\u{FF21}\u{FF21}",
                "http://example.org/%4\u{FF21}",
                "http://\u{661}.\u{662}.\u{663}.\u{664}:\u{661}/",
            ]
        )
        func nonASCIIDigitsAreNotDigits(_ iriString: String) {
            #expect(throws: IRIError.invalidIRI(iriString)) {
                try IRI(validating: iriString)
            }
        }

        @Test("A host of non-ASCII digits is a registered name, not an IPv4 address.")
        func nonASCIIDigitHostIsARegisteredName() throws {
            let iri = try IRI(validating: "http://\u{661}.\u{662}.\u{663}.\u{664}/")

            #expect(iri.authority == "\u{661}.\u{662}.\u{663}.\u{664}")
        }

        @Test("IPvFuture addresses hold only US-ASCII unreserved characters, sub-delims and ':' (RFC 3986 section 3.2.2).")
        func ipvFutureIsASCII() {
            let iriString = "http://[v1.\u{E9}]/"

            #expect(throws: IRIError.invalidIRI(iriString)) {
                try IRI(validating: iriString)
            }
        }
    }
}
