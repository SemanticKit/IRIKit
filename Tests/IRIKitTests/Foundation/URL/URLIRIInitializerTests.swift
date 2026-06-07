import Foundation
import IRIKit
import Testing

@Suite("URL IRI initializer coverage")
struct URLIRIInitializerTests {
    @Test("URL can be constructed directly from an IRI.")
    func createsURLFromIRI() throws {
        let iri = try IRI(validating: "https://example.com/people/renée?view=summary#details")
        let url = URL(iri)

        #expect(url.absoluteString == "https://example.com/people/ren%C3%A9e?view=summary#details")
    }

    @Test("URL can be constructed directly from an IRI reference.")
    func createsURLFromIRIReference() throws {
        let reference = try IRIReference(validating: "../people/renée")
        let url = URL(reference)

        #expect(url.relativeString == "../people/ren%C3%A9e")
    }

    @Test("URL can be constructed directly from an absolute IRI.")
    func createsURLFromAbsoluteIRI() throws {
        let iri = try AbsoluteIRI(validating: "https://example.com/people/renée?view=summary")
        let url = URL(iri)

        #expect(url.absoluteString == "https://example.com/people/ren%C3%A9e?view=summary")
    }
}
