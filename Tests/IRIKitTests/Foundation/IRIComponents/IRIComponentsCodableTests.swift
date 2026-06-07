import Foundation
import IRIKit
import Testing

@Suite("IRIComponents Codable coverage")
struct IRIComponentsCodableTests {
    @Test("IRIComponents provides Codable by encoding and decoding each component value.")
    func encodesAndDecodesEachComponent() throws {
        let components = IRIComponents(
            scheme: "https",
            authority: "example.com",
            path: "/people/renée",
            query: "view=summary",
            fragment: "details"
        )
        let encoded = try JSONEncoder().encode(components)
        let decoded = try JSONDecoder().decode(IRIComponents.self, from: encoded)

        requireCodable(IRIComponents.self)
        #expect(decoded == components)
    }
}
