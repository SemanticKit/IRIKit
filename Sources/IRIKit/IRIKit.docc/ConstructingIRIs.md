# Constructing IRIs

Create, inspect, and reuse Internationalized Resource Identifiers.

## Overview

IRIKit models IRIs as Unicode character sequences while still giving you
Foundation URL conversion for systems that require URI-compatible text. This
guide walks through the common construction paths: creating an absolute IRI,
building an IRI from components, carrying a relative reference, and expanding a
reusable template.

## Create an Absolute IRI

Use ``IRI`` when the value must identify a resource without needing another
base IRI. `IRI` accepts the RFC 3987 `IRI` production, including fragments.

```swift
import Foundation
import IRIKit

let profile = try IRI(validating: "https://example.com/people/renée")
```

The original string remains available as ``IRI/rawValue``.

```swift
profile.rawValue
// "https://example.com/people/renée"
```

When a protocol or format requires a URI-compatible value, construct a
Foundation `URL` from the IRI.

```swift
URL(profile).absoluteString
// "https://example.com/people/ren%C3%A9e"
```

## Require No Fragment

Use ``AbsoluteIRI`` when the value must match RFC 3987's `absolute-IRI`
production. `AbsoluteIRI` has the same scheme, authority, path, and query
component shape as ``IRI``, but rejects fragments.

```swift
let canonical = try AbsoluteIRI(validating: "https://example.com/people/renée")

canonical.path
// "/people/renée"
```

```swift
try AbsoluteIRI(validating: "https://example.com/people/renée#summary")
// Throws IRIError.invalidIRI(_:)
```

## Build from Components

Use ``IRIComponents`` when you want to assemble an IRI from structured generic
syntax components instead of concatenating strings.

```swift
let components = IRIComponents(
    scheme: "https",
    authority: "example.com",
    path: "/people/renée",
    query: "view=summary",
    fragment: "details"
)

let iri = try components.iri()
```

The assembled value is available as ``IRIComponents/string`` and is validated
before ``IRIComponents/iri()`` returns.

```swift
components.string
// "https://example.com/people/renée?view=summary#details"

iri.query
// "view=summary"
```

You can also pass components directly to ``IRI/init(components:)`` when the
call site is already constructing an IRI value.

```swift
let direct = try IRI(components: components)

direct.fragment
// "details"
```

When you already have Foundation components, create ``IRIComponents`` or
``IRI`` from `URLComponents`.

```swift
var foundationComponents = URLComponents()
foundationComponents.scheme = "https"
foundationComponents.host = "example.com"
foundationComponents.path = "/people/renée"

let iriComponents = IRIComponents(foundationComponents)
let foundationIRI = try IRI(foundationComponents)
```

## Inspect the Components

After validation, use the parsed components when your application needs to make
decisions about an identifier.

```swift
profile.scheme
// "https"

profile.authority
// "example.com"

profile.path
// "/people/renée"
```

IRIKit does not treat a scheme as a networking instruction. It only validates
and stores IRI syntax.

## Carry Relative References

Use ``IRIReference`` when the text can be resolved only by the surrounding
document or application context. A reference may also be created from a
Foundation `URL` when the source text is already URI-compatible.

```swift
let section = try IRIReference(validating: "../people/renée#summary")

URL(section).relativeString
// "../people/ren%C3%A9e#summary"
```

The reference stays relative. Resolution against a base IRI belongs to the
calling context.

## Use Static and Sliced Text

``IRI``, ``AbsoluteIRI``, ``IRIReference``, and ``IRITemplate`` support string
literals for fixed values. `IRI`, ``IRIReference``, and ``IRITemplate`` also
support throwing `StaticString` initializers and `Substring` initializers when
validated text comes from a fixed static source or a larger buffer.

```swift
let fixed: IRI = "https://example.com/vocabulary/Person"
let canonical: AbsoluteIRI = "https://example.com/vocabulary/Person"
let staticValue = try IRI("https://example.com/vocabulary/name" as StaticString)

let line = "identifier=https://example.com/vocabulary/label"
let valueStart = line.firstIndex(of: "=")!
let sliced = try IRI(line[line.index(after: valueStart)...])
```

## Reuse Construction Patterns

Use ``IRITemplate`` when callers provide values at runtime but you still want
the final result validated as an absolute IRI.

```swift
let template = try IRITemplate(validating: "https://example.com/{collection}/{name}")

let iri = try template.expand([
    "collection": "people",
    "name": "renée"
])

iri.rawValue
// "https://example.com/people/renée"
```

Missing values are reported as ``IRIError/missingTemplateValue(_:)``. Expanded
text that is not an absolute IRI is reported as ``IRIError/invalidIRI(_:)``.

## Compare Identity Values

IRI equality and ordering use simple string comparison. This keeps identity
behavior predictable and avoids scheme-specific assumptions.

```swift
let first = try IRI(validating: "https://example.com/a")
let second = try IRI(validating: "https://example.com/b")

first < second
// true
```

## Next Steps

Use ``IRI`` anywhere your package needs an absolute standards-backed identifier.
Use ``AbsoluteIRI`` when fragments are out of scope, ``IRIComponents`` for
structured assembly, ``IRIReference`` for document-local links, and
``IRITemplate`` for reusable construction from dynamic values.
