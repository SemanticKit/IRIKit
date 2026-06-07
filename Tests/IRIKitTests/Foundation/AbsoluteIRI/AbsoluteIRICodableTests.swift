import Foundation
import IRIKit
import Testing

@Suite("AbsoluteIRI Codable coverage")
struct AbsoluteIRICodableTests {
    @Test("AbsoluteIRI provides Codable by encoding and decoding its stored value.")
    func encodesAndDecodesStoredValue() throws {
        let iri = try AbsoluteIRI(validating: "https://example.com/rosé")
        let encoded = try JSONEncoder().encode(iri)
        let decoded = try JSONDecoder().decode(AbsoluteIRI.self, from: encoded)

        requireCodable(AbsoluteIRI.self)
        #expect(decoded == iri)
    }
}
