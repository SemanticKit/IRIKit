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

The authority keeps the user, password and port, as RFC 3986 section 3.2
defines it: `[ userinfo "@" ] host [ ":" port ]`. The host comes from
`percentEncodedHost`, so a host set through `components.host` comes out
percent-encoded, not in Foundation's IDNA form.

```swift
var international = URLComponents()
international.scheme = "https"
international.host = "räk.example"

IRIComponents(international).authority
// "r%C3%A4k.example", not "xn--rk-via.example"
```

The port is copied as text, because RFC 3986 section 3.2.3 defines it as
`port = *DIGIT`. Leading zeros and ports too large for `Int` are kept, and a
port delimiter with no digits is kept as an empty port.

```swift
IRIComponents(URLComponents(string: "http://example.com:007/a")!).authority
// "example.com:007", not "example.com:7"

IRIComponents(URLComponents(string: "http://example.com:/a")!).authority
// "example.com:"
```

An IPv6 address needs its brackets. A host set to `"::1"` through
`components.host` is not an IP literal: `URLComponents.string` is `nil` for
it, but its percent-encoded form `%3A%3A1` is a valid RFC 3986 `reg-name`, so
``IRI/init(_:)-(URLComponents)`` accepts it as a registered name.

```swift
var unbracketed = URLComponents()
unbracketed.scheme = "http"
unbracketed.host = "::1"
unbracketed.path = "/"

unbracketed.string
// nil

try IRI(unbracketed).rawValue
// "http://%3A%3A1/", a reg-name host, not the IPv6 loopback address

var bracketed = unbracketed
bracketed.host = "[::1]"

try IRI(bracketed).rawValue
// "http://[::1]/"
```

## Keep the Boundary Explicit

Use IRIKit values for standards-backed IRI identity in your own APIs. Bridge to
Foundation `URL` only at boundaries that require URL values or URI-compatible
strings.
