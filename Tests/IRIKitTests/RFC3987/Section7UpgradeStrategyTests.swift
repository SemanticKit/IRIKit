import Foundation
import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 7.8 upgrading strategy")
    struct Section7UpgradeStrategyTests {
        @Test("IRIs should not be created, generated, or transported before they can be interpreted correctly.")
        func validatesCreatedIRIsBeforeUse() {
            #expect(throws: IRIError.invalidIRI("https://example.com/path with space")) {
                try IRI(validating: "https://example.com/path with space")
            }
        }

        @Test("Generating software should generate IRIs only after service and transport support exist.")
        func generatedIRIsExposeURITransportForm() throws {
            let iri = try IRI(validating: "https://example.com/雪")

            #expect(URL(iri).absoluteString == "https://example.com/%E9%9B%AA")
        }

        @Test("URI-to-IRI display conversion should wait for upgraded entry software.")
        func preservesURIFormWhenNoConversionIsSelected() throws {
            let reference = try IRIReference(validating: "https://example.com/r%C3%A9sum%C3%A9")

            #expect(reference.rawValue == "https://example.com/r%C3%A9sum%C3%A9")
        }

        @Test("UTF-8 should be preferred where there is a free choice of character encodings.")
        func usesUTF8ForMappedOriginalCharacters() throws {
            let iri = try IRI(validating: "https://example.com/é")

            #expect(URL(iri).absoluteString == "https://example.com/%C3%A9")
        }
    }
}
