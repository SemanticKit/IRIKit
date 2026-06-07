import IRIKit
import Testing

@Suite("IRIComponents Sendable coverage")
struct IRIComponentsSendableTests {
    @Test("IRIComponents provides Sendable for concurrent use.")
    func isSendable() {
        requireSendable(IRIComponents.self)
    }
}

