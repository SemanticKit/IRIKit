import IRIKit
import Testing

@Suite("AbsoluteIRI Equatable coverage")
struct AbsoluteIRIEquatableTests {
    @Test("AbsoluteIRI provides Equatable with exact Unicode scalar identity.")
    func comparesExactScalarIdentity() throws {
        let composed = try AbsoluteIRI(validating: "https://example.com/résumé")
        let decomposed = try AbsoluteIRI(validating: "https://example.com/résumé")

        requireEquatable(AbsoluteIRI.self)
        #expect(composed == composed)
        #expect(composed != decomposed)
    }
}
