import IRIKit
import Testing

@Suite("IRITemplate CustomStringConvertible coverage")
struct IRITemplateCustomStringConvertibleTests {
    @Test("IRITemplate CustomStringConvertible should describe the original template text.")
    func describesOriginalTemplateText() throws {
        let template = try IRITemplate(validating: "https://example.com/{name}")

        requireCustomStringConvertible(IRITemplate.self)
        #expect(template.description == "https://example.com/{name}")
    }
}
