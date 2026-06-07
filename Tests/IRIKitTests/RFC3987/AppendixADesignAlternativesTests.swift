import Foundation
import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Appendix A design alternatives")
    struct AppendixADesignAlternativesTests {
        @Test("IRIs do not use new schemes or an IRI metascheme.")
        func acceptsExistingURISchemesWithoutIRIMetascheme() throws {
            let iri = try IRI(validating: "https://example.com/résumé")

            #expect(iri.scheme == "https")
        }

        @Test("IRI-to-URI conversion uses UTF-8, not UTF-7 or another character encoding.")
        func usesUTF8InsteadOfAlternativeCharacterEncodings() throws {
            let iri = try IRI(validating: "https://example.com/résumé")

            #expect(URL(iri).absoluteString == "https://example.com/r%C3%A9sum%C3%A9")
        }

        @Test("IRI-to-URI conversion uses existing octet-based percent-encoding.")
        func usesExistingPercentEncodingConvention() throws {
            let iri = try IRI(validating: "https://example.com/雪")

            #expect(URL(iri).absoluteString == "https://example.com/%E9%9B%AA")
        }

        @Test("IRI syntax does not use in-band charset labels.")
        func rejectsInBandCharsetLabelSyntax() {
            #expect(throws: IRIError.invalidIRI("https://example.com/<utf-8>/雪")) {
                try IRI(validating: "https://example.com/<utf-8>/雪")
            }
        }
    }
}
