# Bridging Foundation Types

Move between IRIKit values and Foundation URL types when a system API requires
URI-compatible text.

## Overview

IRIKit stores Unicode IRI text. Foundation `URL` stores URI-compatible text for
many operations. IRIKit bridges between those forms by mapping non-URI
characters through UTF-8 percent encoding.

## Create Foundation URLs

Create a Foundation `URL` from ``IRI``, ``AbsoluteIRI``, or ``IRIReference``.
The resulting URL contains URI-compatible text.

```swift
let iri = try IRI(validating: "https://example.com/people/renée")
let url = URL(iri)

url.absoluteString
// "https://example.com/people/ren%C3%A9e"
```

```swift
let canonical = try AbsoluteIRI(validating: "https://example.com/people/renée")
let canonicalURL = URL(canonical)

canonicalURL.absoluteString
// "https://example.com/people/ren%C3%A9e"
```

```swift
let reference = try IRIReference(validating: "../people/renée#summary")
let referenceURL = URL(reference)

referenceURL.relativeString
// "../people/ren%C3%A9e#summary"
```

## Create IRIKit Values from URLs

Create ``IRI`` and ``AbsoluteIRI`` from a Foundation `URL` when the URL's
absolute string should become a validated IRI value.

```swift
let url = URL(string: "https://example.com/people/ren%C3%A9e")!

let iri = try IRI(url)

iri.rawValue
// "https://example.com/people/renée"
```

```swift
let canonical = try AbsoluteIRI(url)

canonical.rawValue
// "https://example.com/people/renée"
```

Create ``IRIReference`` from a Foundation `URL` when the URL's relative string
is the intended source.

```swift
let referenceURL = URL(string: "../people/ren%C3%A9e#summary")!
let reference = try IRIReference(referenceURL)

reference.rawValue
// "../people/renée#summary"
```

## Use URL Components

Create ``IRI`` directly from Foundation `URLComponents` when the components
already form an absolute IRI.

```swift
var components = URLComponents()
components.scheme = "https"
components.host = "example.com"
components.path = "/people/renée"
components.query = "view=summary"

let iri = try IRI(components)
```

Create ``IRIComponents`` from Foundation components when you want to keep the
component values available before validation.

```swift
let iriComponents = IRIComponents(components)

iriComponents.string
// "https://example.com/people/ren%C3%A9e?view=summary"
```

## Keep the Boundary Explicit

Use IRIKit values for standards-backed IRI identity in your own APIs. Bridge to
Foundation `URL` only at boundaries that require URL values or URI-compatible
strings.
