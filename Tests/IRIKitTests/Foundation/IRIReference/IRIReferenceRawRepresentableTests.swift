import IRIKit
import Testing

@Suite("IRIReference RawRepresentable coverage")
struct IRIReferenceRawRepresentableTests {
    @Test("IRIReference provides RawRepresentable with rawValue equal to the original reference character sequence.")
    func storesRawValue() {
        let reference = IRIReference(rawValue: "../rosé#section")

        requireRawRepresentable(IRIReference.self)
        #expect(reference?.rawValue == "../rosé#section")
    }
}

