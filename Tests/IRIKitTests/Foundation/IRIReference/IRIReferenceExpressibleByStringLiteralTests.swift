import IRIKit
import Testing

@Suite("IRIReference ExpressibleByStringLiteral coverage")
struct IRIReferenceExpressibleByStringLiteralTests {
    @Test("IRIReference ExpressibleByStringLiteral should validate static reference literals.")
    func createsReferenceFromStringLiteral() {
        let reference: IRIReference = "../people/renée?view=summary#details"

        requireExpressibleByStringLiteral(IRIReference.self)
        #expect(reference.rawValue == "../people/renée?view=summary#details")
    }
}
