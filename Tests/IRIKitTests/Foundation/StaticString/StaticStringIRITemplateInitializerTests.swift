import IRIKit
import Testing

@Suite("StaticString IRITemplate initializer coverage")
struct StaticStringIRITemplateInitializerTests {
    @Test("StaticString should initialize IRITemplate values for validated static templates.")
    func createsIRITemplate() throws {
        let template = try IRITemplate("https://example.com/{name}" as StaticString)

        #expect(template.rawValue == "https://example.com/{name}")
    }
}
