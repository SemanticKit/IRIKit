import IRIKit
import Testing

@Suite("IRITemplate RawRepresentable coverage")
struct IRITemplateRawRepresentableTests {
    @Test("IRITemplate provides RawRepresentable with rawValue equal to the original template text.")
    func storesRawValue() {
        let template = IRITemplate(rawValue: "https://example.com/{name}")

        requireRawRepresentable(IRITemplate.self)
        #expect(template?.rawValue == "https://example.com/{name}")
    }
}

