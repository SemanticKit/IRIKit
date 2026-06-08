# ``IRIKit``

Work with Internationalized Resource Identifiers (IRIs) in Swift.

## Overview

An Internationalized Resource Identifier is a resource identifier that can contain Unicode text. IRIs let code preserve identifiers such as `https://example.com/articles/rosé` without forcing the readable characters into percent-encoded URI form.

Use IRIKit when your Swift code needs to validate, store, inspect, or construct those identifiers as values. The package keeps the original IRI text available for your model code and provides Foundation `URL` conversion when an API requires URI-compatible text.

Choose ``IRI`` for an absolute identifier, ``AbsoluteIRI`` when fragments are not allowed, and ``IRIReference`` when the text may be relative to another identifier. Use ``IRIComponents`` and ``IRIQueryItem`` when an identifier is assembled from separate parts, and use ``IRITemplate`` when part of the identifier is filled in at runtime.

You can build an IRI from the parts of the identifier instead of writing the
whole string yourself. This example uses `scheme`, `authority`, `path`, and
`query`, then asks IRIKit to validate the finished ``IRI``.

```swift
import Foundation
import IRIKit

let article = try IRI(validating: "https://example.com/articles/rosé")
let components = IRIComponents(
    scheme: "https",
    authority: "example.com",
    path: "/articles/rosé",
    query: "view=summary"
)
let componentArticle = try IRI(components: components)

print(article.rawValue)
// https://example.com/articles/rosé

print(componentArticle.rawValue)
// https://example.com/articles/rosé?view=summary

print(URL(article).absoluteString)
// https://example.com/articles/ros%C3%A9
```

If the query comes from form fields, filters, or other name-value data, pass
those values as ``IRIQueryItem`` values instead of joining strings by hand.

```swift
import IRIKit

let components = IRIComponents(
    scheme: "https",
    authority: "example.com",
    path: "/articles/rosé",
    queryItems: [
        IRIQueryItem(name: "view", value: "summary")
    ]
)
let article = try IRI(components: components)

print(article.rawValue)
// https://example.com/articles/rosé?view=summary
```

IRIKit follows [RFC 3987](https://datatracker.ietf.org/doc/html/rfc3987) for IRIs and uses [RFC 3986](https://datatracker.ietf.org/doc/html/rfc3986) where IRI syntax inherits URI rules.

## Topics

### Learn When to Use IRIs

- <doc:ChoosingIRIKitTypes>
- <doc:ConstructingIRIs>
- <doc:BridgingFoundationTypes>

### Work with IRI Values

- ``IRI``
- ``AbsoluteIRI``
- ``IRIReference``

### Build IRIs from Parts

- ``IRIComponents``
- ``IRIQueryItem``
- ``IRITemplate``

### Handle Invalid Text

- ``IRIError``
- <doc:HandlingValidationAndIdentity>
- <doc:UsingIRIKitValues>
