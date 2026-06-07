import IRIKit
import Testing

@Suite("Substring IRIReference initializer coverage")
struct SubstringIRIReferenceInitializerTests {
    @Test("Substring should initialize IRIReference values without forcing callers to allocate a String first.")
    func createsIRIReference() throws {
        let text = "prefix ../rosé#section suffix"
        let start = text.firstIndex(of: ".")!
        let end = text[start...].firstIndex(of: " ")!
        let reference = try IRIReference(text[start..<end])

        #expect(reference.rawValue == "../rosé#section")
    }
}
