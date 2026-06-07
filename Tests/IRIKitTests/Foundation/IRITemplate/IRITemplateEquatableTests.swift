import IRIKit
import Testing

@Suite("IRITemplate Equatable coverage")
struct IRITemplateEquatableTests {
    @Test("IRITemplate provides Equatable by comparing template text.")
    func comparesTemplateText() throws {
        let lhs = try IRITemplate(validating: "https://example.com/{name}")
        let rhs = try IRITemplate(validating: "https://example.com/{name}")
        let other = try IRITemplate(validating: "https://example.com/{id}")

        requireEquatable(IRITemplate.self)
        #expect(lhs == rhs)
        #expect(lhs != other)
    }
}
