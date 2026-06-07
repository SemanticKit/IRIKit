import IRIKit
import Testing

@Suite("Substring IRITemplate initializer coverage")
struct SubstringIRITemplateInitializerTests {
    @Test("Substring should initialize IRITemplate values without forcing callers to allocate a String first.")
    func createsIRITemplate() throws {
        let text = "prefix https://example.com/{name} suffix"
        let start = text.firstIndex(of: "h")!
        let end = text[start...].firstIndex(of: " ")!
        let template = try IRITemplate(text[start..<end])

        #expect(template.rawValue == "https://example.com/{name}")
    }
}
