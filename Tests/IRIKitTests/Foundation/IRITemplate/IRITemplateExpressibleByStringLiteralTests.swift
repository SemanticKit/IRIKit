import IRIKit
import Testing

@Suite("IRITemplate ExpressibleByStringLiteral coverage")
struct IRITemplateExpressibleByStringLiteralTests {
    @Test("IRITemplate ExpressibleByStringLiteral should validate static template literals.")
    func createsTemplateFromStringLiteral() {
        let template: IRITemplate = "https://example.com/{collection}/{name}"

        requireExpressibleByStringLiteral(IRITemplate.self)
        #expect(template.rawValue == "https://example.com/{collection}/{name}")
    }
}
