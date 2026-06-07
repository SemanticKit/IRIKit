import IRIKit
import Testing

@Suite("AbsoluteIRI Sendable coverage")
struct AbsoluteIRISendableTests {
    @Test("AbsoluteIRI provides Sendable for concurrency-safe value transfer.")
    func requiresSendable() {
        requireSendable(AbsoluteIRI.self)
    }
}
