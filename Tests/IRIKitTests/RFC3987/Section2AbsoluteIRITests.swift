import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 2.2 absolute-IRI syntax")
    struct Section2AbsoluteIRITests {
        @Test(
            "absolute-IRI = scheme ':' ihier-part [ '?' iquery ]",
            arguments: [
                "https://example.com/path",
                "https://example.com/path?query",
                "urn:example:animal:ferret:nose",
            ]
        )
        func acceptsAbsoluteIRIWithoutFragment(_ iriString: String) throws {
            let iri = try AbsoluteIRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }

        @Test(
            "absolute-IRI excludes ifragment.",
            arguments: [
                "https://example.com/path#fragment",
                "urn:example#fragment",
            ]
        )
        func rejectsAbsoluteIRIFragments(_ iriString: String) {
            #expect(throws: IRIError.invalidIRI(iriString)) {
                try AbsoluteIRI(validating: iriString)
            }
        }

        @Test(
            "IRI includes ifragment.",
            arguments: [
                "https://example.com/path#fragment",
                "urn:example#fragment",
            ]
        )
        func acceptsIRIFragments(_ iriString: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }
    }
}
