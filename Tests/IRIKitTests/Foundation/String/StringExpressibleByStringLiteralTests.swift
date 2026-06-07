import Testing

@Suite("String ExpressibleByStringLiteral coverage")
struct StringExpressibleByStringLiteralTests {
    @Test("String provides ExpressibleByStringLiteral by accepting a string literal as the value itself.")
    func acceptsStringLiteral() {
        let value: String = "https://example.com/rosé"

        requireExpressibleByStringLiteral(String.self)
        #expect(value == "https://example.com/rosé")
    }
}

