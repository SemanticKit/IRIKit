import IRIKit
import Testing

@Suite("IRIReference CustomStringConvertible coverage")
struct IRIReferenceCustomStringConvertibleTests {
    @Test("IRIReference provides CustomStringConvertible with the original reference character sequence.")
    func describesOriginalCharacterSequence() throws {
        let reference = try IRIReference(validating: "../rosé#section")

        requireCustomStringConvertible(IRIReference.self)
        #expect(reference.description == "../rosé#section")
    }
}

