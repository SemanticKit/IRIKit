import Foundation
import IRIKit
import Testing

@Suite("URLComponents IRIComponents initializer coverage")
struct URLComponentsIRIComponentsInitializerTests {
    @Test("URLComponents should initialize IRIComponents from Foundation component storage.")
    func createsIRIComponents() {
        let urlComponents = URLComponents(string: "https://example.com/people/ren%C3%A9e?view=summary#details")!
        let components = IRIComponents(urlComponents)

        #expect(components.scheme == "https")
        #expect(components.authority == "example.com")
        #expect(components.path == "/people/ren%C3%A9e")
        #expect(components.query == "view=summary")
        #expect(components.fragment == "details")
    }

    @Test(
        "authority = [ userinfo '@' ] host [ ':' port ] keeps userinfo, port, IPv6 literals and an empty host.",
        arguments: [
            ("https://user@example.com/a", "user@example.com"),
            ("https://user:secret@example.com/a", "user:secret@example.com"),
            ("https://us%20er@example.com/a", "us%20er@example.com"),
            ("https://example.com:8080/a", "example.com:8080"),
            ("https://user:secret@example.com:8080/a", "user:secret@example.com:8080"),
            ("http://[::1]:8080/a", "[::1]:8080"),
            ("http://[2001:db8::7]/a", "[2001:db8::7]"),
            ("file:///etc/hosts", ""),
            ("http://:80/a", ":80"),
        ]
    )
    func assemblesAuthority(_ string: String, _ authority: String) {
        let components = IRIComponents(URLComponents(string: string)!)

        #expect(components.authority == authority)
    }

    @Test("URLComponents without user, password, host or port should give no authority.")
    func omitsAbsentAuthority() {
        let components = IRIComponents(URLComponents(string: "urn:example:a")!)

        #expect(components.authority == nil)
        #expect(components.path == "example:a")
    }
}
