import IRIKit
import Testing

@Suite("IRI Sendable coverage")
struct IRISendableTests {
    @Test("IRI provides Sendable for concurrent use.")
    func isSendable() {
        requireSendable(IRI.self)
    }
}

