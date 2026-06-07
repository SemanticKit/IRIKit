import Foundation
import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 2.2 percent-encoding syntax")
    struct Section2PercentEncodingTests {
        @Test(
            "pct-encoded = '%' HEXDIG HEXDIG",
            arguments: [
                "https://example.com/%00",
                "https://example.com/%7E",
                "https://example.com/%ff",
                "https://example.com/%Ff",
            ]
        )
        func acceptsHexDigitPercentTriplets(_ iriString: String) throws {
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
        }

        @Test(
            "pct-encoded requires exactly two hexadecimal digits.",
            arguments: [
                "https://example.com/%",
                "https://example.com/%0",
                "https://example.com/%0G",
                "https://example.com/%GG",
            ]
        )
        func rejectsMalformedPercentTriplets(_ iriString: String) {
            #expect(throws: IRIError.invalidIRI(iriString)) {
                try IRI(validating: iriString)
            }
        }

        @Test("Existing percent-encoded sequences are not encoded again during IRI-to-URI mapping.")
        func preservesExistingPercentEncodedSequencesDuringMapping() throws {
            let iri = try IRI(validating: "https://example.com/red%09rosé#red")

            #expect(URL(iri).absoluteString == "https://example.com/red%09ros%C3%A9#red")
        }
    }
}
