# Handling Validation and Identity

Validate IRI text at the boundary and compare values by their stored Unicode
character sequences.

## Overview

IRIKit validates syntax when a value is created. Once construction succeeds, the
stored text is the value's identity. Normalization returns a new value and
never changes the stored text. The library does not perform network access or
application-level resolution.

## Report Validation Failures

Use throwing initializers when invalid input should produce an error.

```swift
do {
    _ = try IRI(validating: "1https://example.com")
} catch IRIError.invalidIRI(let text) {
    print(text)
}
```

``IRIError`` distinguishes invalid absolute IRIs, invalid references, missing
template values, invalid template syntax, and a normal form that cannot be
written as IRI text (``IRIError/normalFormHasNoText(_:)``).

```swift
let template = try IRITemplate(validating: "https://example.com/{name}")

try template.expand([:])
// Throws IRIError.missingTemplateValue("name")
```

Template syntax is validated separately from expansion.

```swift
try IRITemplate(validating: "https://example.com/{name")
// Throws IRIError.invalidTemplate(_:)
```

Relative-reference validation reports ``IRIError/invalidIRIReference(_:)`` when
the supplied text is outside RFC 3987 reference syntax.

Use failable initializers when `nil` is the correct failure representation.

```swift
let iri = IRI("https://example.com/valid")
let invalid = IRI("1https://example.com")
```

## Compare and Store Values

``IRI``, ``AbsoluteIRI``, and ``IRIReference`` compare, sort, hash, and encode
using their stored Unicode scalar sequences. ``IRITemplate`` uses the same
identity rule for template text.

```swift
let first = try IRI(validating: "https://example.com/a")
let second = try IRI(validating: "https://example.com/b")

first < second
// true
```

```swift
let names: Set<IRI> = [
    try IRI(validating: "https://example.com/name"),
    try IRI(validating: "https://example.com/name"),
]

names.count
// 1
```

Equality is simple string comparison, so `http://example.org/%7Euser` and
`http://example.org/~user` are different values. To compare spelling
variants of the same identifier, compare normal forms instead; see
<doc:ComparingAndNormalizingIRIs>.

```swift
let encoded = try IRI(validating: "http://example.org/%7Euser")
let plain = try IRI(validating: "http://example.org/~user")

encoded == plain
// false

try encoded.isEquivalent(to: plain)
// true
```

## Preserve IRI Text

Use `rawValue` when you need the original validated IRI text, and use
`description` when an API needs the value's lossless string representation.

```swift
let iri = try IRI(validating: "https://example.com/people/renée")

iri.rawValue
// "https://example.com/people/renée"

iri.description
// "https://example.com/people/renée"
```

Use Foundation bridging when the consumer needs URI-compatible text.

```swift
URL(iri).absoluteString
// "https://example.com/people/ren%C3%A9e"
```
