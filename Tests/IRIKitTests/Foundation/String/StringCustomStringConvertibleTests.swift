import Testing

@Suite("String CustomStringConvertible coverage")
struct StringCustomStringConvertibleTests {
    @Test("String provides CustomStringConvertible by returning itself as its description.")
    func describesItself() {
        let value = "https://example.com/rosé"

        requireCustomStringConvertible(String.self)
        #expect(value.description == "https://example.com/rosé")
    }
}

