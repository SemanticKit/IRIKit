# IRIKit

IRIKit provides Swift value types for working with RFC 3987
Internationalized Resource Identifiers (IRIs).

Use IRIKit to validate IRI text, inspect parsed components, build IRIs from
components, preserve exact Unicode identity, and bridge to Foundation URL types
when URI-compatible text is required.

## Installation

Add IRIKit as a Swift Package Manager dependency:

```swift
dependencies: [
    .package(url: "https://github.com/SemanticKit/IRIKit.git", branch: "main"),
]
```

Then add `IRIKit` to the target that uses it:

```swift
.target(
    name: "YourTarget",
    dependencies: ["IRIKit"]
)
```

## Usage

Create an absolute IRI with validation:

```swift
import IRIKit

let iri = try IRI(validating: "https://example.com/people/renée#profile")

iri.scheme
// "https"

iri.authority
// "example.com"

iri.path
// "/people/renée"

iri.fragment
// "profile"
```

Use `AbsoluteIRI` when fragments are not allowed:

```swift
let canonical = try AbsoluteIRI(validating: "https://example.com/people/renée")
```

Use `IRIReference` when relative references or fragment-only references are
valid input:

```swift
let reference = try IRIReference(validating: "../people/renée#profile")
```

Build values from components when callers provide generic IRI syntax pieces:

```swift
var components = IRIComponents(
    scheme: "https",
    authority: "example.com",
    path: "/people/renée"
)
components.query = "view=summary"

let built = try components.iri()
```

Bridge to Foundation when another API needs URI-compatible text:

```swift
import Foundation

URL(iri).absoluteString
// "https://example.com/people/ren%C3%A9e#profile"
```

## Core Types

- `IRI`: An absolute RFC 3987 IRI that may include a fragment.
- `AbsoluteIRI`: An RFC 3987 `absolute-IRI`, which excludes fragments.
- `IRIReference`: An absolute, relative, or fragment IRI reference.
- `IRIComponents`: Mutable component storage for assembling an IRI.
- `IRITemplate`: A reusable template that expands runtime values into an IRI.
- `IRIError`: Validation and template-expansion errors.

## Standards

IRIKit follows RFC 3987 for IRI syntax, references, comparison, and URI mapping.
It uses RFC 3986 where RFC 3987 inherits URI generic syntax.

A local copy of RFC 3987 is included at `Documentation/RFC3987.md`.
