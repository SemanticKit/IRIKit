import Foundation
import Testing

@Suite("URL CustomStringConvertible coverage")
struct URLCustomStringConvertibleTests {
    @Test("URL provides CustomStringConvertible using its absolute string description.")
    func describesAbsoluteString() {
        let url = URL(string: "https://example.com/ros%C3%A9")!

        requireCustomStringConvertible(URL.self)
        #expect(url.description == "https://example.com/ros%C3%A9")
    }
}

