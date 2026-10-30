import Foundation
import IRIKit
import Testing

@Suite("URLComponents IRI initializer coverage")
struct URLComponentsIRIInitializerTests {
    @Test("URLComponents should initialize an IRI after Foundation component assembly produces a valid absolute URL.")
    func createsIRI() throws {
        let components = URLComponents(string: "https://example.com/people/ren%C3%A9e?view=summary#details")!
        let iri = try IRI(components)

        #expect(iri.rawValue == "https://example.com/people/ren%C3%A9e?view=summary#details")
    }

    @Test(
        "URLComponents with userinfo, port, an IPv6 literal or an empty host should initialize an IRI with the same authority.",
        arguments: [
            ("https://user:secret@example.com/a", "user:secret@example.com"),
            ("https://example.com:8080/a", "example.com:8080"),
            ("http://[::1]:8080/a", "[::1]:8080"),
            ("file:///etc/hosts", ""),
            ("http://example.com:/a", "example.com:"),
            ("http://[::1]:/a", "[::1]:"),
            ("http://h:007/a", "h:007"),
            ("http://h:99999999999999999999/a", "h:99999999999999999999"),
        ]
    )
    func keepsAuthority(_ string: String, _ authority: String) throws {
        let iri = try IRI(URLComponents(string: string)!)

        #expect(iri.rawValue == string)
        #expect(iri.authority == authority)
    }

    @Test("URLComponents should be assembled through IRIComponents, so a path beginning with '//' without an authority is rejected.")
    func checksAssembledComponents() {
        var components = URLComponents()
        components.scheme = "urn"
        components.percentEncodedPath = "//a"

        #expect(throws: IRIError.invalidIRI("urn://a")) {
            try IRI(components)
        }
    }

    @Test("URLComponents whose authority and path would read back differently should not initialize an IRI.")
    func rejectsComponentsThatDoNotRoundTrip() {
        var hostAndRootlessPath = URLComponents()
        hostAndRootlessPath.scheme = "https"
        hostAndRootlessPath.host = "example.com"
        hostAndRootlessPath.percentEncodedPath = "a"

        #expect(throws: IRIError.invalidIRI("https://example.coma")) {
            try IRI(hostAndRootlessPath)
        }

        var userAndRootlessPath = URLComponents()
        userAndRootlessPath.scheme = "urn"
        userAndRootlessPath.user = "u"
        userAndRootlessPath.percentEncodedPath = "x"

        #expect(throws: IRIError.invalidIRI("urn://u@x")) {
            try IRI(userAndRootlessPath)
        }
    }

    @Test("URLComponents without a scheme should not initialize an IRI.")
    func rejectsMissingScheme() {
        let components = URLComponents(string: "//example.com/a")!

        #expect(throws: IRIError.invalidIRI("://example.com/a")) {
            try IRI(components)
        }
    }

    @Test("An IPv6 zone ID host should not initialize an IRI: RFC 3986 IP-literal has no zone ID, which RFC 6874 adds.")
    func rejectsZoneIdentifier() {
        let components = URLComponents(string: "http://[fe80::1%25en0]/")!

        #expect(throws: IRIError.invalidIRI("http://[fe80::1%25en0]/")) {
            try IRI(components)
        }
    }

    @Test("""
        A host set to "::1" without brackets is not an IPv6 literal: URLComponents.string is nil, \
        but the percent-encoded host "%3A%3A1" is a valid RFC 3986 reg-name, so an IRI is created.
        """)
    func acceptsUnbracketedIPv6HostAsRegName() throws {
        var components = URLComponents()
        components.scheme = "http"
        components.host = "::1"
        components.path = "/"

        #expect(components.string == nil)

        let iri = try IRI(components)

        #expect(iri.rawValue == "http://%3A%3A1/")
        #expect(iri.authority == "%3A%3A1")

        components.port = 8080

        #expect(try IRI(components).rawValue == "http://%3A%3A1:8080/")
    }
}
