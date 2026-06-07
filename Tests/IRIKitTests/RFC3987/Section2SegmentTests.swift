import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 2.2 segment syntax")
    struct Section2SegmentTests {
        @Test(
            "isegment = *ipchar",
            arguments: [
                "urn:",
                "urn:/",
                "urn:/alpha",
                "urn:/alpha/",
            ]
        )
        func acceptsZeroOrMoreIPCharsInSegment(_ iriString: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }

        @Test(
            "isegment-nz = 1*ipchar",
            arguments: [
                "urn:a",
                "urn:%41",
                "urn:@",
                "urn::",
            ]
        )
        func acceptsNonZeroSegments(_ iriString: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }

        @Test(
            "isegment-nz-nc excludes ':'.",
            arguments: [
                "relative/path",
                "relative@path",
                "relative%41path",
            ]
        )
        func acceptsNoSchemeRelativeFirstSegments(_ referenceString: String) throws {
            let reference = try IRIReference(validating: referenceString)

            #expect(reference.rawValue == referenceString)
        }

        @Test("First-match-wins applies to ambiguous productions.")
        func firstColonSelectsTheIRIBranch() throws {
            let reference = try IRIReference(validating: "a:b")
            let iri = try IRI(validating: "a:b")

            #expect(reference.rawValue == iri.rawValue)
            #expect(iri.scheme == "a")
        }
    }
}
