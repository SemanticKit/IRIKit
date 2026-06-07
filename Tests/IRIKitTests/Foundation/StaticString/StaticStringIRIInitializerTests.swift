import IRIKit
import Testing

@Suite("StaticString IRI initializer coverage")
struct StaticStringIRIInitializerTests {
    @Test("StaticString should initialize IRI values for validated static identifiers.")
    func createsIRI() throws {
        let iri = try IRI("https://example.com/rosé" as StaticString)

        #expect(iri.rawValue == "https://example.com/rosé")
    }
}
