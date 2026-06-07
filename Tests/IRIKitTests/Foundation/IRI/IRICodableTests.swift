import Foundation
import IRIKit
import Testing

@Suite("IRI Codable coverage")
struct IRICodableTests {
    @Test("IRI provides Codable by encoding and decoding its stored value.")
    func encodesAndDecodesStoredValue() throws {
        let iri = try IRI(validating: "https://example.com/rosé")
        let encoded = try JSONEncoder().encode(iri)
        let decoded = try JSONDecoder().decode(IRI.self, from: encoded)

        requireCodable(IRI.self)
        #expect(decoded == iri)
    }
}

