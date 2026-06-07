import Foundation
import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 1.2 applicability")
    struct Section1ApplicabilityTests {
        @Test("IRI-to-URI mapping is well-defined and deterministic.")
        func mapsTheSameIRIToTheSameURIEveryTime() throws {
            let iri = try IRI(validating: "https://example.com/résumé")

            #expect(URL(iri).absoluteString == "https://example.com/r%C3%A9sum%C3%A9")
            #expect(URL(iri).absoluteString == "https://example.com/r%C3%A9sum%C3%A9")
        }

        @Test("IRI-capable protocol or format elements carry the IRI character sequence directly.")
        func preservesDirectIRITextForIRICapableCarriers() throws {
            let iri = try IRI(validating: "https://example.com/雪")

            #expect(iri.rawValue == "https://example.com/雪")
        }

        @Test("URI-only protocol elements receive the corresponding URI character sequence.")
        func mapsIRITextForURIOnlyCarriers() throws {
            let iri = try IRI(validating: "https://example.com/雪")

            #expect(URL(iri).absoluteString == "https://example.com/%E9%9B%AA")
        }

        @Test("Carrier formats must provide a way to represent the IRI character repertoire.")
        func storesCarrierTextAsIRICharacters() throws {
            let iri = try IRI(validating: "https://example.com/雪")

            #expect(iri.rawValue == "https://example.com/雪")
            #expect(URL(iri).absoluteString == "https://example.com/%E9%9B%AA")
        }
    }
}
