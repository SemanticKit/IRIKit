import IRIKit
import Testing

@Suite("IRITemplate LosslessStringConvertible coverage")
struct IRITemplateLosslessStringConvertibleTests {
    @Test("IRITemplate LosslessStringConvertible should recreate a validated template from its description.")
    func recreatesTemplateFromDescription() {
        let description = "https://example.com/{collection}/{name}"
        let template = IRITemplate(description)

        requireLosslessStringConvertible(IRITemplate.self)
        #expect(template?.rawValue == "https://example.com/{collection}/{name}")
        #expect(template?.description == "https://example.com/{collection}/{name}")
    }

    @Test("IRITemplate LosslessStringConvertible should reject invalid template syntax.")
    func rejectsInvalidDescription() {
        let description = "https://example.com/{name"

        #expect(IRITemplate(description) == nil)
    }
}
