import Foundation
import IRIKit
import Testing

extension RFC3987ComplianceTests {
    @Suite("Section 5.3.3 and 5.3.4 scheme and protocol normalization")
    struct Section5SchemeProtocolNormalizationTests {
        @Test("Scheme-based normalization belongs to the defining scheme specification.")
        func genericIdentityDoesNotApplySchemeNormalization() throws {
            let explicit = try IRI(validating: "custom://example.com:/")
            let implicit = try IRI(validating: "custom://example.com/")

            #expect(explicit != implicit)
        }

        @Test("HTTP scheme-based normalization treats empty path, empty port, and default port as equivalent where the scheme defines them.")
        func exactIdentityKeepsHTTPDefaultFormsDistinct() throws {
            let noPath = try IRI(validating: "http://example.com")
            let slash = try IRI(validating: "http://example.com/")
            let emptyPort = try IRI(validating: "http://example.com:/")
            let defaultPort = try IRI(validating: "http://example.com:80/")

            #expect(noPath != slash)
            #expect(slash != emptyPort)
            #expect(emptyPort != defaultPort)
        }

        @Test("Scheme-based normalization handles empty authority and empty host only when the scheme licenses that equivalence.")
        func exactIdentityKeepsAuthorityAndNoAuthorityDistinct() throws {
            let authority = try IRI(validating: "file://localhost/path")
            let noAuthority = try IRI(validating: "file:/path")

            #expect(authority != noAuthority)
        }

        @Test("Scheme-based normalization does not remove delimiters for empty components without scheme permission.")
        func exactIdentityPreservesEmptyQueryDelimiter() throws {
            let emptyQuery = try IRI(validating: "http://example.com/?")
            let noQuery = try IRI(validating: "http://example.com/")

            #expect(emptyQuery != noQuery)
        }

        @Test("Fragment delimiter presence is significant for scheme-based normalization.")
        func exactIdentityPreservesEmptyFragmentDelimiter() throws {
            let emptyFragment = try IRI(validating: "http://example.com/#")
            let noFragment = try IRI(validating: "http://example.com/")

            #expect(emptyFragment != noFragment)
        }

        @Test("IDN ireg-name normalization may use ToASCII and Nameprep where a scheme uses domain names.")
        func genericIdentityKeepsUnicodeAndACEHostsDistinct() throws {
            let unicode = try IRI(validating: "http://résumé.example.org")
            let ace = try IRI(validating: "http://xn--rsum-bpad.example.org")

            #expect(unicode != ace)
        }

        @Test("IDN scheme-based normalization validates IDNs with ToASCII and Nameprep but keeps legible IRI form.")
        func preservesLegibleUnicodeHostForm() throws {
            let iri = try IRI(validating: "http://résumé.example.org")

            #expect(iri.authority == "résumé.example.org")
        }

        @Test("Scheme-based normalization may consider IDN components and punycode conversions equivalent.")
        func doesNotApplyIDNPunycodeEquivalenceGenerically() throws {
            let unicode = try IRI(validating: "http://résumé.example.org")
            let punycode = try IRI(validating: "http://xn--rsum-bpad.example.org")

            #expect(URL(unicode).absoluteString != URL(punycode).absoluteString)
        }

        @Test("Protocol-based normalization requires protocol evidence such as redirects.")
        func exactIdentityDoesNotUseProtocolObservations() throws {
            let source = try IRI(validating: "http://example.com/data")
            let redirected = try IRI(validating: "http://example.com/data/")

            #expect(source != redirected)
        }

        @Test("Protocol-based normalization can treat redirect-related trailing slash IRIs as equivalent only after protocol evidence.")
        func genericComparisonKeepsRedirectCandidatesDistinct() throws {
            let source = try IRI(validating: "http://example.com/data")
            let target = try IRI(validating: "http://example.com/data/")

            #expect(source.rawValue != target.rawValue)
        }
    }
}
