import Foundation
import IRIKit
import Testing

@Suite("URLComponents IRI initializer coverage")
struct URLComponentsIRIInitializerTests {
    @Test("URLComponents should initialize an IRI after Foundation component assembly produces a valid absolute URL.")
    func createsIRI() throws {
        let components = URLComponents(string: "https://example.com/people/ren%C3%A9e?view=summary#details")!
        let iri = try IRI(components)

        #expect(iri.rawValue == "https://example.com/people/ren%C3%A9e?view=summary#details")
    }
}
