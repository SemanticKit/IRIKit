# Using IRIKit Values

Store, compare, encode, and transfer IRIKit values using their standards-backed
value semantics.

## Overview

IRIKit types are plain Swift values. After validation succeeds, the stored
Unicode scalar sequence is the value's identity. The library does not fetch
resources, apply scheme-specific normalization, or resolve references against a
base IRI.

## Store and Compare Identifiers

``IRI``, ``AbsoluteIRI``, and ``IRIReference`` conform to `Equatable`,
`Hashable`, and `Comparable`. Equality and hashing use exact Unicode scalar
identity, and ordering uses simple string ordering.

```swift
let first = try IRI(validating: "https://example.com/name")
let second = try IRI(validating: "https://example.com/name")

first == second
// true

let identifiers: Set<IRI> = [first, second]

identifiers.count
// 1
```

```swift
let a = try AbsoluteIRI(validating: "https://example.com/a")
let b = try AbsoluteIRI(validating: "https://example.com/b")

a < b
// true
```

## Encode and Decode Values

``IRI``, ``AbsoluteIRI``, ``IRIReference``, ``IRIComponents``, and
``IRITemplate`` conform to `Codable`.

```swift
let encoder = JSONEncoder()
let iri = try IRI(validating: "https://example.com/people/renée")

let data = try encoder.encode(iri)
let decoded = try JSONDecoder().decode(IRI.self, from: data)

decoded.rawValue
// "https://example.com/people/renée"
```

## Use String Representations

``IRI``, ``AbsoluteIRI``, ``IRIReference``, and ``IRITemplate`` conform to
`RawRepresentable` and `LosslessStringConvertible`. Use `rawValue` or
`description` when a Swift API needs the original IRIKit text.

```swift
let reference = try IRIReference(validating: "../people/renée#summary")

reference.rawValue
// "../people/renée#summary"

reference.description
// "../people/renée#summary"
```

``IRIComponents`` uses its assembled string as its description and can recreate
component values from a valid absolute IRI string.

```swift
let components = IRIComponents("https://example.com/people/renée#summary")

components?.description
// "https://example.com/people/renée#summary"
```

## Transfer Across Concurrency Boundaries

IRIKit public value types conform to `Sendable`, so they can cross Swift
concurrency boundaries after validation.

```swift
func loadResource(named iri: IRI) async {
    print(iri.rawValue)
}

let iri = try IRI(validating: "https://example.com/resource")

await loadResource(named: iri)
```

