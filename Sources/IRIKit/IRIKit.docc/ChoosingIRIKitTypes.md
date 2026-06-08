# Choosing IRIKit Types

Select the IRIKit value type that matches the identifier role in your API.

## Overview

IRIKit keeps the standards role of a value visible in its Swift type. Use the
narrowest type that matches the value your code accepts or returns.

## Absolute Resource Identifiers

Use ``IRI`` for a complete RFC 3987 IRI. An `IRI` always has a scheme and may
also include an authority, path, query, and fragment.

```swift
let article = try IRI(validating: "https://example.com/articles/rosé#intro")

article.scheme
// "https"

article.fragment
// "intro"
```

Use ``AbsoluteIRI`` when a fragment is not allowed. This is the RFC 3987
`absolute-IRI` production.

```swift
let canonical = try AbsoluteIRI(validating: "https://example.com/articles/rosé")

canonical.query
// nil
```

## References

Use ``IRIReference`` when the string may be relative to a base IRI or may be a
fragment-only reference. IRIKit validates the reference syntax and leaves
resolution to the surrounding document or application context.

```swift
let chapter = try IRIReference(validating: "../articles/rosé#intro")
let fragment = try IRIReference(validating: "#intro")
```

## Components

Use ``IRIComponents`` when callers supply separate generic syntax pieces. The
components remain mutable until you assemble and validate them.

```swift
var components = IRIComponents(
    scheme: "https",
    authority: "example.com",
    path: "/articles/rosé"
)

components.fragment = "intro"

let article = try IRI(components: components)
```

Use ``IRIQueryItem`` when query names and values are available separately. The
items assemble into the query component and the complete IRI is validated when
you create the final value.

```swift
let queryComponents = IRIComponents(
    scheme: "https",
    authority: "example.com",
    path: "/articles/rosé",
    queryItems: [
        IRIQueryItem(name: "view", value: "summary"),
        IRIQueryItem(name: "draft")
    ]
)

let article = try IRI(components: queryComponents)

print(article.query!)
// view=summary&draft
```

Use the failable string initializer on ``IRIComponents`` when you need to
inspect a validated IRI as component values.

```swift
let parsed = IRIComponents("https://example.com/articles/rosé#intro")

parsed?.fragment
// "intro"
```

## Templates

Use ``IRITemplate`` when part of the identifier is supplied at runtime. Template
expansion returns a validated ``IRI``.

```swift
let template = try IRITemplate(validating: "https://example.com/{collection}/{slug}")

let iri = try template.expand([
    "collection": "articles",
    "slug": "rosé",
])
```

## Text Sources

Use throwing validation when invalid input must be reported, and use the failable
`RawRepresentable` or `LosslessStringConvertible` initializers when failure can
be represented as `nil`.

```swift
let required = try IRI(validating: "https://example.com/required")
let optional = IRI("https://example.com/optional")
let raw = IRI(rawValue: "https://example.com/raw")
let explicit = IRI(string: "https://example.com/string")
```

The same optional construction pattern is available on ``AbsoluteIRI``,
``IRIReference``, and ``IRITemplate`` when invalid input should become `nil`.

```swift
let canonical = AbsoluteIRI("https://example.com/canonical")
let reference = IRIReference("../relative/path")
let template = IRITemplate("https://example.com/{name}")
```

For fixed values, `IRI`, ``IRIReference``, and ``IRITemplate`` support string
literals and throwing `StaticString` initializers.

```swift
let vocabulary: IRI = "https://example.com/vocabulary/name"
let fixed = try IRI("https://example.com/vocabulary/label" as StaticString)
```

For text sliced from a larger buffer, use the `Substring` initializers on
``IRI``, ``IRIReference``, and ``IRITemplate``.

```swift
let line = "iri=https://example.com/vocabulary/comment"
let separator = line.firstIndex(of: "=")!
let iri = try IRI(line[line.index(after: separator)...])
```

## Complete API Surface

Use this table to find the supported construction and conversion path for each
public IRIKit type.

| Type | Use it for | Construction paths |
| --- | --- | --- |
| ``IRI`` | Absolute IRIs that may include fragments | `validating:`, `components:`, `rawValue:`, string description, `string:`, string literal, `StaticString`, `Substring`, Foundation `URL`, Foundation `URLComponents` |
| ``AbsoluteIRI`` | Absolute IRIs that must not include fragments | `validating:`, `rawValue:`, string description, string literal, Foundation `URL` |
| ``IRIReference`` | Absolute, relative, and fragment references | `validating:`, `rawValue:`, string description, string literal, `StaticString`, `Substring`, Foundation `URL` |
| ``IRIComponents`` | Mutable component assembly | component initializer, query-item initializer, valid IRI string description, Foundation `URLComponents` |
| ``IRIQueryItem`` | Query item assembly | `name:value:`, `string`, string description |
| ``IRITemplate`` | Reusable runtime expansion | `validating:`, `rawValue:`, string description, string literal, `StaticString`, `Substring`, `expand(_:)` |
