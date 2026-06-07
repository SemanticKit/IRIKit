# ``IRIKit``

Construct standards-backed Internationalized Resource Identifiers (IRIs) in Swift.

## Overview

IRIKit provides small value types for validating, inspecting, constructing, and
bridging Internationalized Resource Identifiers in Swift.

Use ``IRI`` when a value must be an absolute Internationalized Resource
Identifier, including an optional fragment. Use ``AbsoluteIRI`` when the value
must match RFC 3987's `absolute-IRI` production and therefore must not include a
fragment. Use ``IRIReference`` when a value may be relative to another IRI. Use
``IRIComponents`` or Foundation `URLComponents` when you want component-based
construction. Use ``IRIQueryItem`` when callers provide query names and values
separately, and use ``IRITemplate`` when you need a reusable construction
pattern that expands runtime values into a validated IRI.

The library preserves IRI text as Unicode and provides Foundation URL
conversion when a protocol or format requires URI-compatible characters.

```swift
import Foundation
import IRIKit

let article = try IRI(validating: "https://example.com/articles/rosé")
let components = IRIComponents(
    scheme: "https",
    authority: "example.com",
    path: "/articles/rosé",
    queryItems: [
        IRIQueryItem(name: "view", value: "summary")
    ]
)

print(article.rawValue)
// https://example.com/articles/rosé

print(try components.iri().rawValue)
// https://example.com/articles/rosé?view=summary

print(URL(article).absoluteString)
// https://example.com/articles/ros%C3%A9
```

### Choosing a Type

- Use ``IRI`` for absolute identifiers that stand on their own and may include
  fragments.
- Use ``AbsoluteIRI`` for absolute identifiers that must not include fragments.
- Use ``IRIComponents`` for structured construction from generic syntax
  components.
- Use ``IRIQueryItem`` for structured query construction before validation.
- Use ``IRIReference`` for document links, fragments, and relative references.
- Use ``IRITemplate`` for reusable construction of absolute IRIs from named
  values.
- Use Foundation `URL` and `URLComponents` bridging when an API requires
  URI-compatible text.

### Standards

IRIKit follows [RFC 3987](https://datatracker.ietf.org/doc/html/rfc3987) for
Internationalized Resource Identifiers and uses
[RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986) where RFC 3987
inherits URI generic syntax.

## Topics

### Getting Started

- <doc:ChoosingIRIKitTypes>
- <doc:ConstructingIRIs>
- <doc:BridgingFoundationTypes>
- <doc:HandlingValidationAndIdentity>
- <doc:UsingIRIKitValues>

### Creating IRIs

Use ``IRI`` for absolute identifiers that may include fragments,
``AbsoluteIRI`` for absolute identifiers without fragments, and
``IRIReference`` for relative or fragment references.

### Building IRIs from Components

Use ``IRIComponents`` to assemble an IRI from generic syntax components,
``IRIQueryItem`` for query names and values, and ``IRITemplate`` for reusable
runtime construction.

### Handling Errors

Handle ``IRIError`` when validation rejects invalid IRI text.
