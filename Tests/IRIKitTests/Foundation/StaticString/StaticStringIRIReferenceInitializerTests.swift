import IRIKit
import Testing

@Suite("StaticString IRIReference initializer coverage")
struct StaticStringIRIReferenceInitializerTests {
    @Test("StaticString should initialize IRIReference values for validated static references.")
    func createsIRIReference() throws {
        let reference = try IRIReference("../rosé#section" as StaticString)

        #expect(reference.rawValue == "../rosé#section")
    }
}
