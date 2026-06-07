import Foundation
import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 1 definitions and applicability")
    struct Section1DefinitionsTests {
        @Test("An IRI is a sequence of characters from UCS, not a sequence of octets.")
        func storesIRIAsCharacterSequence() throws {
            let iriString = "https://example.com/résumé"
            let iri = try IRI(validating: iriString)

            #expect(iri.rawValue == iriString)
            #expect(iri.rawValue.utf8.count != iri.rawValue.count)
        }

        @Test("An IRI reference may be absolute or relative.")
        func acceptsAbsoluteAndRelativeIRIReferences() throws {
            let absolute = try IRIReference(validating: "https://example.com/résumé")
            let relative = try IRIReference(validating: "../résumé")

            #expect(absolute.rawValue == "https://example.com/résumé")
            #expect(relative.rawValue == "../résumé")
        }

        @Test("The corresponding URI must encode original characters into octets using UTF-8.")
        func mapsOriginalCharactersToUTF8URIForm() throws {
            let iri = try IRI(validating: "https://example.com/résumé")

            #expect(URL(iri).absoluteString == "https://example.com/r%C3%A9sum%C3%A9")
        }

        @Test("Direct IRI use belongs only in protocol or format elements designated to carry IRIs.")
        func distinguishesDirectIRITextFromURIForm() throws {
            let iri = try IRI(validating: "https://example.com/雪")

            #expect(iri.rawValue == "https://example.com/雪")
            #expect(URL(iri).absoluteString == "https://example.com/%E9%9B%AA")
        }
    }
}
