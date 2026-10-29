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

        @Test(
            "HTTP scheme-based normalization makes the four RFC 3987 section 5.3.3 example IRIs equivalent.",
            .tags(.normalization),
            arguments: [
                "http://example.com",
                "http://example.com/",
                "http://example.com:/",
                "http://example.com:80/",
            ]
        )
        func httpDefaultFormsAreEquivalent(_ string: String) throws {
            let iri = try IRI(validating: string)

            #expect(try iri.normalized(.syntaxAndSchemeBased).rawValue == "http://example.com/")
        }

        @Test(
            "Scheme-based normalization removes empty and default ports and supplies an empty path as '/'.",
            .tags(.normalization),
            arguments: [
                NormalizationCase("HTTPS://Example.org:443", .syntaxAndSchemeBased, expected: "https://example.org/"),
                NormalizationCase("https://example.org:443/a?b", .syntaxAndSchemeBased, expected: "https://example.org/a?b"),
                NormalizationCase("https://example.org?q", .syntaxAndSchemeBased, expected: "https://example.org/?q"),
                NormalizationCase("https://example.org#f", .syntaxAndSchemeBased, expected: "https://example.org/#f"),
                NormalizationCase("http://example.org:443/", .syntaxAndSchemeBased, expected: "http://example.org:443/"),
                NormalizationCase("https://example.org:80/", .syntaxAndSchemeBased, expected: "https://example.org:80/"),
                NormalizationCase("http://example.org:8080", .syntaxAndSchemeBased, expected: "http://example.org:8080/"),
                NormalizationCase("http://example.org:0080/", .syntaxAndSchemeBased, expected: "http://example.org/"),
                NormalizationCase("http://user@example.org:80/", .syntaxAndSchemeBased, expected: "http://user@example.org/"),
                NormalizationCase("http://[::1]:80", .syntaxAndSchemeBased, expected: "http://[::1]/"),
                NormalizationCase("http://192.0.2.1:/", .syntaxAndSchemeBased, expected: "http://192.0.2.1/"),
                NormalizationCase("ws://example.org:80", .syntaxAndSchemeBased, expected: "ws://example.org/"),
                NormalizationCase("wss://example.org:443/chat", .syntaxAndSchemeBased, expected: "wss://example.org/chat"),
                NormalizationCase("ftp://example.org:21", .syntaxAndSchemeBased, expected: "ftp://example.org/"),
            ]
        )
        func schemeBasedNormalization(_ testCase: NormalizationCase) throws {
            let iri = try IRI(validating: testCase.input)

            #expect(try iri.normalized(testCase.normalization).rawValue == testCase.expected)
        }

        @Test(
            "Scheme-based normalization leaves schemes without a known rule unchanged.",
            .tags(.normalization),
            arguments: [
                NormalizationCase("custom://example.com:/", .scheme, expected: "custom://example.com:/"),
                NormalizationCase("custom://example.com", .scheme, expected: "custom://example.com"),
                NormalizationCase("file:/path", .scheme, expected: "file:/path"),
                NormalizationCase("urn:example:Animal:ferret:nose", .scheme, expected: "urn:example:Animal:ferret:nose"),
                NormalizationCase("mailto:Someone@Example.org", .syntaxAndSchemeBased, expected: "mailto:Someone@Example.org"),
            ]
        )
        func unknownSchemesAreUnchanged(_ testCase: NormalizationCase) throws {
            let iri = try IRI(validating: testCase.input)

            #expect(try iri.normalized(testCase.normalization).rawValue == testCase.expected)
        }

        @Test(
            "Scheme-based normalization keeps empty query and fragment delimiters.",
            .tags(.normalization)
        )
        func keepsEmptyComponentDelimiters() throws {
            let emptyQuery = try IRI(validating: "http://example.com/?")
            let emptyFragment = try IRI(validating: "http://example.com/#")
            let bare = try IRI(validating: "http://example.com")

            #expect(try emptyQuery.normalized(.syntaxAndSchemeBased).rawValue == "http://example.com/?")
            #expect(try emptyFragment.normalized(.syntaxAndSchemeBased).rawValue == "http://example.com/#")
            #expect(try !emptyQuery.isEquivalent(to: bare, under: .syntaxAndSchemeBased))
            #expect(try !emptyFragment.isEquivalent(to: bare, under: .syntaxAndSchemeBased))
        }

        @Test(
            "Scheme-based normalization rejects HTTP-family IRIs without a host.",
            .tags(.normalization),
            arguments: ["https:/relative", "http:relative", "http://:80/", "ws://user@/chat"]
        )
        func requiresHostForHTTPFamily(_ string: String) throws {
            let iri = try IRI(validating: string)

            #expect(throws: IRIError.invalidIRI(string)) {
                _ = try iri.normalized(.syntaxAndSchemeBased)
            }
            #expect(try iri.normalized(.syntaxBased).scheme == iri.scheme)
        }

        @Test(
            "Scheme-based normalization treats an IDN and its Punycode form as equivalent and keeps the legible form.",
            .tags(.normalization),
            arguments: [
                SimpleComparisonCase(lhs: "http://résumé.example.org", rhs: "http://xn--rsum-bpad.example.org", areEqual: true),
                SimpleComparisonCase(lhs: "https://bücher.example/", rhs: "https://XN--BCHER-KVA.example/", areEqual: true),
                SimpleComparisonCase(lhs: "https://BÜCHER.Example/", rhs: "https://bücher.example/", areEqual: true),
                SimpleComparisonCase(lhs: "http://他们为什么不说中文.example", rhs: "http://xn--ihqwcrb4cv8a8dqg056pqjye.example", areEqual: true),
                SimpleComparisonCase(lhs: "http://3年B組金八先生.example", rhs: "http://xn--3B-ww4c5e180e575a65lsy2b.example", areEqual: true),
                SimpleComparisonCase(lhs: "https://bücher.example/", rhs: "https://bucher.example/", areEqual: false),
                SimpleComparisonCase(lhs: "custom://résumé.example.org", rhs: "custom://xn--rsum-bpad.example.org", areEqual: false),
            ]
        )
        func idnPunycodeEquivalence(_ testCase: SimpleComparisonCase) throws {
            let lhs = try IRI(validating: testCase.lhs)
            let rhs = try IRI(validating: testCase.rhs)

            #expect(try lhs.isEquivalent(to: rhs, under: .syntaxAndSchemeBased) == testCase.areEqual)
        }

        @Test(
            "IDN scheme-based normalization produces the legible Unicode host, not ACE.",
            .tags(.normalization),
            arguments: [
                NormalizationCase("http://xn--rsum-bpad.example.org", .syntaxAndSchemeBased, expected: "http://résumé.example.org/"),
                NormalizationCase("https://Ｅｘａｍｐｌｅ.org/", .syntaxAndSchemeBased, expected: "https://example.org/"),
                NormalizationCase("https://xn--invalid-.example/", .syntaxAndSchemeBased, expected: "https://xn--invalid-.example/"),
                NormalizationCase("https://xn--.example/", .syntaxAndSchemeBased, expected: "https://xn--.example/"),
            ]
        )
        func idnNormalFormIsLegible(_ testCase: NormalizationCase) throws {
            let iri = try IRI(validating: testCase.input)

            #expect(try iri.normalized(testCase.normalization).rawValue == testCase.expected)
        }

        @Test(
            "IDN host mapping never turns a fullwidth percent sign into a percent-encoding (RFC 3987 section 8).",
            .tags(.normalization),
            arguments: ["http://x\u{FF05}/", "http://a\u{FF05}41/", "https://\u{FF05}7E.example/"]
        )
        func fullwidthPercentSignInHostIsNotAnEncoding(_ string: String) throws {
            let iri = try IRI(validating: string)
            let normalized = try iri.normalized(.syntaxAndSchemeBased)

            #expect(!normalized.rawValue.contains("%"))
            #expect(try normalized.normalized(.syntaxAndSchemeBased) == normalized)
            #expect(try !iri.isEquivalent(to: IRI(validating: "http://aa/"), under: .syntaxAndSchemeBased))
        }

        @Test(
            "IDN host mapping never splits a label into more labels (RFC 3987 section 8).",
            .tags(.normalization),
            arguments: [
                SimpleComparisonCase(lhs: "http://www.google\u{2488}com/", rhs: "http://www.google1.com/", areEqual: false),
                SimpleComparisonCase(lhs: "http://www.google\u{2488}com/", rhs: "http://www.google1.com./", areEqual: false),
                SimpleComparisonCase(lhs: "http://example\u{3002}org/", rhs: "http://example.org/", areEqual: false),
                SimpleComparisonCase(lhs: "http://example\u{FF0E}org/", rhs: "http://example.org/", areEqual: false),
                SimpleComparisonCase(lhs: "http://example\u{FF61}org/", rhs: "http://example.org/", areEqual: false),
                SimpleComparisonCase(lhs: "http://xn--a-ecp.ru/", rhs: "http://a1..ru/", areEqual: false),
                SimpleComparisonCase(lhs: "http://xn--a-ecp.ru/", rhs: "http://a\u{2488}.ru/", areEqual: true),
            ]
        )
        func compatibilityMappingKeepsLabelBoundaries(_ testCase: SimpleComparisonCase) throws {
            let lhs = try IRI(validating: testCase.lhs)
            let rhs = try IRI(validating: testCase.rhs)
            let normalized = try lhs.normalized(.syntaxAndSchemeBased)
            let labelCount = { (iri: IRI) in iri.rawValue.split(separator: "/")[1].split(separator: ".", omittingEmptySubsequences: false).count }

            #expect(try lhs.isEquivalent(to: rhs, under: .syntaxAndSchemeBased) == testCase.areEqual)
            #expect(labelCount(normalized) == labelCount(lhs))
            #expect(try normalized.normalized(.syntaxAndSchemeBased) == normalized)
        }

        @Test(
            "IDN normalization leaves an ACE label longer than a DNS label undecoded.",
            .tags(.normalization)
        )
        func overlongACELabelIsNotDecoded() throws {
            let label = "xn--" + String(repeating: "a", count: 60) + "-ecp"
            let iri = try IRI(validating: "http://\(label).example/")

            #expect(try iri.normalized(.syntaxAndSchemeBased).rawValue == "http://\(label).example/")
        }
    }
}
