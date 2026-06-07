import IRIKit
import Testing

@Suite("AbsoluteIRI CustomStringConvertible coverage")
struct AbsoluteIRICustomStringConvertibleTests {
    @Test("AbsoluteIRI provides CustomStringConvertible with the original absolute IRI character sequence.")
    func describesOriginalCharacterSequence() throws {
        let iri = try AbsoluteIRI(validating: "https://example.com/rosé")

        requireCustomStringConvertible(AbsoluteIRI.self)
        #expect(iri.description == "https://example.com/rosé")
    }
}
