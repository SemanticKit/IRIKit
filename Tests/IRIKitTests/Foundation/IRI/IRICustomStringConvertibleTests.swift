import IRIKit
import Testing

@Suite("IRI CustomStringConvertible coverage")
struct IRICustomStringConvertibleTests {
    @Test("IRI provides CustomStringConvertible with the original IRI character sequence.")
    func describesOriginalCharacterSequence() throws {
        let iri = try IRI(validating: "https://example.com/rosé")

        requireCustomStringConvertible(IRI.self)
        #expect(iri.description == "https://example.com/rosé")
    }
}

