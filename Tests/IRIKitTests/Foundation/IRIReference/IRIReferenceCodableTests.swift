import Foundation
import IRIKit
import Testing

@Suite("IRIReference Codable coverage")
struct IRIReferenceCodableTests {
    @Test("IRIReference provides Codable by encoding and decoding its stored value.")
    func encodesAndDecodesStoredValue() throws {
        let reference = try IRIReference(validating: "../rosé#section")
        let encoded = try JSONEncoder().encode(reference)
        let decoded = try JSONDecoder().decode(IRIReference.self, from: encoded)

        requireCodable(IRIReference.self)
        #expect(decoded == reference)
    }
}

