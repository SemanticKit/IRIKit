import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 2.2 character classes")
    struct Section2CharacterClassTests {
        @Test(
            "iunreserved = ALPHA / DIGIT / '-' / '.' / '_' / '~' / ucschar",
            arguments: [
                "https://example.com/\u{00A0}",
                "https://example.com/\u{D7FF}",
                "https://example.com/\u{F900}",
                "https://example.com/\u{FDCF}",
                "https://example.com/\u{FDF0}",
                "https://example.com/\u{FFEF}",
                "https://example.com/\u{10000}",
                "https://example.com/\u{1FFFD}",
                "https://example.com/\u{20000}",
                "https://example.com/\u{2FFFD}",
                "https://example.com/\u{30000}",
                "https://example.com/\u{3FFFD}",
                "https://example.com/\u{40000}",
                "https://example.com/\u{4FFFD}",
                "https://example.com/\u{50000}",
                "https://example.com/\u{5FFFD}",
                "https://example.com/\u{60000}",
                "https://example.com/\u{6FFFD}",
                "https://example.com/\u{70000}",
                "https://example.com/\u{7FFFD}",
                "https://example.com/\u{80000}",
                "https://example.com/\u{8FFFD}",
                "https://example.com/\u{90000}",
                "https://example.com/\u{9FFFD}",
                "https://example.com/\u{A0000}",
                "https://example.com/\u{AFFFD}",
                "https://example.com/\u{B0000}",
                "https://example.com/\u{BFFFD}",
                "https://example.com/\u{C0000}",
                "https://example.com/\u{CFFFD}",
                "https://example.com/\u{D0000}",
                "https://example.com/\u{DFFFD}",
                "https://example.com/\u{E1000}",
                "https://example.com/\u{EFFFD}",
            ]
        )
        func acceptsUCSCharRanges(_ iriString: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }

        @Test(
            "iprivate may occur only in iquery.",
            arguments: [
                "https://example.com/path?\u{E000}",
                "https://example.com/path?\u{F8FF}",
                "https://example.com/path?\u{F0000}",
                "https://example.com/path?\u{FFFFD}",
                "https://example.com/path?\u{100000}",
                "https://example.com/path?\u{10FFFD}",
            ]
        )
        func acceptsPrivateCharactersInQuery(_ iriString: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }

        @Test(
            "iprivate is not part of ipchar or ifragment.",
            arguments: [
                "https://example.com/\u{E000}",
                "https://example.com/path#\u{E000}",
                "https://example.com/\u{F0000}",
                "https://example.com/path#\u{100000}",
            ]
        )
        func rejectsPrivateCharactersOutsideQuery(_ iriString: String) {
            #expect(throws: IRIError.invalidIRI(iriString)) {
                try IRI(validating: iriString)
            }
        }

        @Test(
            "Printable US-ASCII characters outside URI syntax are not IRI characters.",
            arguments: [
                "https://example.com/<",
                "https://example.com/>",
                "https://example.com/\"",
                "https://example.com/path with space",
                "https://example.com/{",
                "https://example.com/}",
                "https://example.com/|",
                "https://example.com/\\",
                "https://example.com/^",
                "https://example.com/`",
            ]
        )
        func rejectsPrintableASCIIOutsideIRISyntax(_ iriString: String) {
            #expect(throws: IRIError.invalidIRI(iriString)) {
                try IRI(validating: iriString)
            }
        }
    }
}
