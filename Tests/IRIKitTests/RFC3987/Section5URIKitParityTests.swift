import IRIKit
import Testing

extension RFC3987ComplianceTests {
    /// Carries over each behaviour of URIKit's `URINormalizer` and
    /// `LegacyXMLIRICompatibility`, stated in RFC 3987 terms.
    @Suite("Section 5.3 normalization of former URIKit cases", .tags(.normalization, .uriKitParity))
    struct Section5URIKitParityTests {
        @Test("Strict normalization canonicalizes scheme, host, path, and default port.", .tags(.normalization, .uriKitParity))
        func canonicalizesSchemeHostPathAndDefaultPort() throws {
            let iri = try IRI(validating: "HTTPS://BÜCHER.Example:443/a/./b/../c")
            let normalized = try iri.normalized(.syntaxAndSchemeBased)

            // URIKit produced the ACE form "https://xn--bcher-kva.example/a/c".
            // RFC 3987 section 5.3.3 keeps the legible IDN and treats the ACE
            // form as equivalent.
            #expect(normalized.rawValue == "https://bücher.example/a/c")
            #expect(try iri.isEquivalent(
                to: IRI(validating: "https://xn--bcher-kva.example/a/c"),
                under: .syntaxAndSchemeBased
            ))
        }

        @Test(
            "Whitespace is not allowed in an IRI.",
            .tags(.normalization, .uriKitParity),
            arguments: [
                "https://example.org/with space",
                " https://example.org/",
                "https://example.org/\n",
                "https://example.org/\ttab",
            ]
        )
        func rejectsWhitespace(_ string: String) {
            // Deliberate change from URIKit, which trimmed surrounding
            // whitespace before its strict check and so accepted
            // " https://example.org/". IRIKit validates the text it is given;
            // trimming belongs to the boundary decoder that read the text.
            #expect(throws: IRIError.invalidIRI(string)) {
                _ = try IRI(validating: string)
            }
        }

        @Test("Empty input is not an IRI.", .tags(.normalization, .uriKitParity), arguments: ["", "  \n \t  "])
        func rejectsEmptyInput(_ string: String) {
            #expect(throws: IRIError.invalidIRI(string)) {
                _ = try IRI(validating: string)
            }
        }

        @Test("Text without a scheme is not an absolute IRI.", .tags(.normalization, .uriKitParity))
        func rejectsMissingScheme() {
            #expect(throws: IRIError.invalidIRI("//example.org/a")) {
                _ = try IRI(validating: "//example.org/a")
            }
        }

        @Test("HTTP-family IRIs require a host under scheme-based normalization.", .tags(.normalization, .uriKitParity))
        func requiresAuthorityForHTTPFamily() throws {
            let iri = try IRI(validating: "https:/relative")

            #expect(throws: IRIError.invalidIRI("https:/relative")) {
                _ = try iri.normalized(.syntaxAndSchemeBased)
            }
        }

        @Test(
            "ws, wss and ftp IRIs also require a host, as RFC 6455 section 3 and RFC 1738 section 5 do.",
            .tags(.normalization, .uriKitParity),
            arguments: ["ws:/chat", "wss://:443/chat", "ftp:/pub", "ftp://user@/pub"]
        )
        func requiresHostForWebSocketAndFTP(_ string: String) throws {
            let iri = try IRI(validating: string)

            #expect(throws: IRIError.invalidIRI(string)) {
                _ = try iri.normalized(.syntaxAndSchemeBased)
            }
        }

        @Test("Without scheme-based normalization an HTTP IRI without a host still normalizes.", .tags(.normalization, .uriKitParity))
        func lenientNormalizationAllowsMissingHost() throws {
            let iri = try IRI(validating: "HTTPS:/a/../relative")

            #expect(try iri.normalized(.syntaxBased).rawValue == "https:/relative")
        }

        @Test("Authority-free URNs are allowed and keep their case-sensitive parts.", .tags(.normalization, .uriKitParity))
        func allowsAuthorityFreeURN() throws {
            let iri = try IRI(validating: "URN:example:Animal:ferret:nose")

            #expect(try iri.normalized(.syntaxAndSchemeBased).rawValue == "urn:example:Animal:ferret:nose")
        }

        @Test("Hosts are lowercased for every scheme that uses the generic authority syntax.", .tags(.normalization, .uriKitParity))
        func lowercasesHostForAnyScheme() throws {
            let iri = try IRI(validating: "Custom://Example.ORG/Path")

            #expect(try iri.normalized().rawValue == "custom://example.org/Path")
        }

        @Test(
            "Authority schemes normalize an empty path to '/'.",
            .tags(.normalization, .uriKitParity),
            arguments: ["http", "https", "ftp", "ws", "wss"]
        )
        func authoritySchemesUseRootPath(_ scheme: String) throws {
            let iri = try IRI(validating: "\(scheme)://example.org")

            #expect(try iri.normalized(.syntaxAndSchemeBased).rawValue == "\(scheme)://example.org/")
        }

        // URIKit dropped default ports and required a host only for http and
        // https. The ws and wss defaults come from RFC 6455 section 3 ("the
        // default for "ws" is port 80, while the default for "wss" is port
        // 443") and the ftp default from RFC 1738 section 3.2 ("If :<port> is
        // omitted, the port defaults to 21").
        @Test(
            "Default ports are also removed for ws and wss (RFC 6455 section 3) and ftp (RFC 1738 section 3.2), beyond what URIKit did.",
            .tags(.normalization, .uriKitParity),
            arguments: [
                NormalizationCase("ws://example.org:80/", .syntaxAndSchemeBased, expected: "ws://example.org/"),
                NormalizationCase("wss://example.org:443/", .syntaxAndSchemeBased, expected: "wss://example.org/"),
                NormalizationCase("ftp://example.org:21/", .syntaxAndSchemeBased, expected: "ftp://example.org/"),
                NormalizationCase("ws://example.org:443/", .syntaxAndSchemeBased, expected: "ws://example.org:443/"),
                NormalizationCase("wss://example.org:80/", .syntaxAndSchemeBased, expected: "wss://example.org:80/"),
                NormalizationCase("ftp://example.org:80/", .syntaxAndSchemeBased, expected: "ftp://example.org:80/"),
                NormalizationCase("ws://example.org:/", .syntaxAndSchemeBased, expected: "ws://example.org/"),
                NormalizationCase("ftp://example.org", .syntaxAndSchemeBased, expected: "ftp://example.org/"),
            ]
        )
        func removesDefaultPortsBeyondURIKit(_ testCase: NormalizationCase) throws {
            #expect(try IRI(validating: testCase.input).normalized(testCase.normalization).rawValue == testCase.expected)
        }

        @Test("Only the scheme's own default port is removed.", .tags(.normalization, .uriKitParity))
        func removesOnlyMatchingDefaultPort() throws {
            #expect(try IRI(validating: "http://example.org:80/").normalized(.syntaxAndSchemeBased).rawValue == "http://example.org/")
            #expect(try IRI(validating: "https://example.org:443/").normalized(.syntaxAndSchemeBased).rawValue == "https://example.org/")
            #expect(try IRI(validating: "http://example.org:443/").normalized(.syntaxAndSchemeBased).rawValue == "http://example.org:443/")
            #expect(try IRI(validating: "custom://example.org:80/").normalized(.syntaxAndSchemeBased).rawValue == "custom://example.org:80/")
        }

        @Test(
            "Dot segments are removed, a trailing slash is kept, and empty segments are kept as RFC 3986 section 5.2.4 requires.",
            .tags(.normalization, .uriKitParity),
            arguments: [
                NormalizationCase("https://example.org/a/b/../c/", expected: "https://example.org/a/c/"),
                NormalizationCase("https://example.org/..", expected: "https://example.org/"),
                // URIKit dropped the slash after a final "..", giving "/a".
                NormalizationCase("https://example.org/a/b/..", expected: "https://example.org/a/"),
                // URIKit collapsed "a//b" to "a/b", which changes the path.
                NormalizationCase("https://example.org/a//b", expected: "https://example.org/a//b"),
            ]
        )
        func removesDotSegments(_ testCase: NormalizationCase) throws {
            #expect(try IRI(validating: testCase.input).normalized(testCase.normalization).rawValue == testCase.expected)
        }

        @Test("Legacy XML identifier text is not an IRI until the XML layer has decoded it.", .tags(.normalization, .uriKitParity))
        func legacyXMLTextIsNotAnIRI() {
            let legacy = "HTTPS://Example.org\\folder\\file name?a=1&amp;b=2"

            #expect(throws: IRIError.invalidIRI(legacy)) {
                _ = try IRI(validating: legacy)
            }
        }

        @Test("An XML identifier decoded by its format normalizes like any other IRI.", .tags(.normalization, .uriKitParity))
        func decodedXMLIdentifierNormalizes() throws {
            // RFC 3987 section 5.2: format escaping such as XML entities is
            // resolved by the format before comparison. The decoded text is
            // what URIKit's legacy compatibility layer produced before it
            // called the normalizer.
            let decoded = try IRI(validating: "HTTPS://Example.org/folder/file%20name?a=1&b=2")

            #expect(try decoded.normalized(.syntaxAndSchemeBased).rawValue == "https://example.org/folder/file%20name?a=1&b=2")
        }
    }
}
