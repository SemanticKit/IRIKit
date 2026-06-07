# IRIKit

IRIKit owns standards-backed Internationalized Resource Identifier support.

## Source Authorities

Use these standards as implementation authority:

1. RFC 3987, Internationalized Resource Identifiers (IRIs):
   <https://datatracker.ietf.org/doc/html/rfc3987>
   Local reference text: `Documentation/RFC3987.md`
2. RFC 3986, Uniform Resource Identifier (URI): Generic Syntax:
   <https://datatracker.ietf.org/doc/html/rfc3986>

RFC 3987 is the primary authority for IRI syntax, IRI references, mapping IRIs
to URIs, comparison, normalization, bidirectional IRIs, and use requirements.
RFC 3986 is supporting authority where RFC 3987 inherits URI component syntax,
reserved characters, relative-reference behavior, and URI comparison concepts.

## API Shape References

These articles are reading material for Swift API ergonomics. They are not
standards authority and must not override RFC requirements.

- Modern URL construction in Swift:
  <https://www.swiftbysundell.com/articles/modern-url-construction-in-swift/>
- Defining static URLs using string literals:
  <https://www.swiftbysundell.com/tips/defining-static-urls-using-string-literals/>
- Constructing URLs in Swift:
  <https://www.swiftbysundell.com/articles/constructing-urls-in-swift/>

Use these references to evaluate Swift-facing API shape such as static values,
literal ergonomics, component-based construction, dynamic path/query assembly,
and template-like construction. Do not copy Foundation URL behavior when it
conflicts with RFC 3987 or when it introduces URL-specific behavior that is not
part of IRIKit.

## Design Boundary

IRIKit provides IRI and URI-adjacent foundation types only. The target may
define IRI values, IRI references, IRI templates, parsing, validation,
comparison, normalization, and URI mapping as required by the IRI and URI
standards.

## RFC Compliance Tests

RFC 3987 coverage belongs in `Tests/IRIKitTests/RFC3987/RFC3987ComplianceTests.swift`.
That suite is the executable assertion surface for standards compliance.

## Improvement Candidates

1. Add append-style APIs.
   `iri.appending(pathComponent:)`, `iri.appending(pathComponents:)`, and `iri.appending(queryItems:)` would make dynamic IRI construction feel closer to modern `URL` APIs from [Modern URL construction in Swift](https://www.swiftbysundell.com/articles/modern-url-construction-in-swift/) while still validating the assembled RFC 3987 text.

2. Add an `IRIQueryItem` value type.
   This gives query construction a structured API instead of raw strings, while keeping encoding/mapping RFC-backed.

3. Consider a macro later.
   A `#iri("https://example.com/…")` macro could validate static IRIs at compile time, mirroring the modern static URL macro idea. That should be a later slice because it adds tooling surface.

4. Improve `IRITemplate`.
   Current templates expand raw string values. A better version would support typed values and explicit expansion policies for path segments vs query values.
