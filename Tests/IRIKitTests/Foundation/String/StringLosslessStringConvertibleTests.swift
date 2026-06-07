import Testing

@Suite("String LosslessStringConvertible coverage")
struct StringLosslessStringConvertibleTests {
    @Test("String provides LosslessStringConvertible by recreating the same value from its description.")
    func recreatesItselfFromDescription() {
        let value = "https://example.com/rosé"

        requireLosslessStringConvertible(String.self)
        #expect(String(value.description) == value)
    }
}

