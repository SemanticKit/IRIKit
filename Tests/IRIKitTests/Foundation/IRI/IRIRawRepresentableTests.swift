import IRIKit
import Testing

@Suite("IRI RawRepresentable coverage")
struct IRIRawRepresentableTests {
    @Test("IRI provides RawRepresentable with rawValue equal to the original IRI character sequence.")
    func storesRawValue() {
        let iri = IRI(rawValue: "https://example.com/rosé")

        requireRawRepresentable(IRI.self)
        #expect(iri?.rawValue == "https://example.com/rosé")
    }
}

