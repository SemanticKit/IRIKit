import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 2.2 relative reference syntax")
    struct Section2RelativeReferenceTests {
        @Test(
            "irelative-ref = irelative-part [ '?' iquery ] [ '#' ifragment ]",
            arguments: [
                "//example.com/path",
                "/absolute/path",
                "noscheme/path",
                "",
                "?query",
                "#fragment",
                "noscheme/path?query#fragment",
            ]
        )
        func acceptsRelativeReferenceAlternatives(_ referenceString: String) throws {
            let reference = try IRIReference(validating: referenceString)

            #expect(reference.rawValue == referenceString)
        }

        @Test(
            "irelative-part = '//' iauthority ipath-abempty / ipath-absolute / ipath-noscheme / ipath-empty",
            arguments: [
                "//例え.テスト/path",
                "/résumé.html",
                "résumé.html",
                "",
            ]
        )
        func acceptsRelativePartAlternatives(_ referenceString: String) throws {
            let reference = try IRIReference(validating: referenceString)

            #expect(reference.rawValue == referenceString)
        }

        @Test(
            "A colon before any '/', '?', or '#' selects the IRI branch when the prefix is a valid scheme.",
            arguments: [
                "first:segment/path",
                "a:b",
            ]
        )
        func colonAfterValidSchemeSelectsIRIBranch(_ referenceString: String) throws {
            let reference = try IRIReference(validating: referenceString)

            #expect(reference.rawValue == referenceString)
        }

        @Test(
            "ipath-noscheme first segment cannot contain ':' when the prefix is not a valid scheme.",
            arguments: [
                "1:first/path",
                "+:path",
            ]
        )
        func rejectsColonInFirstSegmentWithoutValidScheme(_ referenceString: String) {
            #expect(throws: IRIError.invalidIRIReference(referenceString)) {
                try IRIReference(validating: referenceString)
            }
        }

        @Test(
            "Relative references with authority require iauthority.",
            arguments: [
                "//",
                "///path",
            ]
        )
        func acceptsEmptyRelativeAuthority(_ referenceString: String) throws {
            let reference = try IRIReference(validating: referenceString)

            #expect(reference.rawValue == referenceString)
        }
    }
}
