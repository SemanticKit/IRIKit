import Foundation
import IRIKit
import Testing

@Suite("IRITemplate Codable coverage")
struct IRITemplateCodableTests {
    @Test("IRITemplate provides Codable by encoding and decoding its template text.")
    func encodesAndDecodesTemplateText() throws {
        let template = try IRITemplate(validating: "https://example.com/{name}")
        let encoded = try JSONEncoder().encode(template)
        let decoded = try JSONDecoder().decode(IRITemplate.self, from: encoded)

        requireCodable(IRITemplate.self)
        #expect(decoded == template)
    }
}
