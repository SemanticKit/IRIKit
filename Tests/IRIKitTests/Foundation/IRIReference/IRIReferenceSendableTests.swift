import IRIKit
import Testing

@Suite("IRIReference Sendable coverage")
struct IRIReferenceSendableTests {
    @Test("IRIReference provides Sendable for concurrent use.")
    func isSendable() {
        requireSendable(IRIReference.self)
    }
}

