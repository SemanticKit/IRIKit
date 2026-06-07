import IRIKit
import Testing

@Suite("IRITemplate Sendable coverage")
struct IRITemplateSendableTests {
    @Test("IRITemplate provides Sendable for concurrent use.")
    func isSendable() {
        requireSendable(IRITemplate.self)
    }
}

