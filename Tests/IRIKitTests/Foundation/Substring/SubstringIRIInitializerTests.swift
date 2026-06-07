import IRIKit
import Testing

@Suite("Substring IRI initializer coverage")
struct SubstringIRIInitializerTests {
    @Test("Substring should initialize IRI values without forcing callers to allocate a String first.")
    func createsIRI() throws {
        let text = "prefix https://example.com/rosé suffix"
        let start = text.firstIndex(of: "h")!
        let end = text[start...].firstIndex(of: " ")!
        let iri = try IRI(text[start..<end])

        #expect(iri.rawValue == "https://example.com/rosé")
    }
}
