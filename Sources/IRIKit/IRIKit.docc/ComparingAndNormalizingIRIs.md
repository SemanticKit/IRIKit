# Comparing and Normalizing IRIs

Choose how strictly two IRIs must match, from exact text to the normal forms
of RFC 3987 section 5.

## Overview

RFC 3987 section 5.3 describes a comparison ladder. Each step up the ladder
treats more spellings of the same identifier as equal, at more cost and with
more assumptions about the scheme. IRIKit gives each step its own API so the
choice stays visible at the call site.

| Step | RFC 3987 | IRIKit |
| --- | --- | --- |
| Simple string comparison | 5.3.1 | `==`, `<`, `hash(into:)` |
| Syntax-based normalization | 5.3.2 | ``IRINormalization/syntaxBased`` |
| Scheme-based normalization | 5.3.3 | ``IRINormalization/scheme`` |
| Protocol-based normalization | 5.3.4 | Not provided: it needs network evidence such as redirects |

Normalization never changes the value you hold. ``IRI/normalized(_:)``
returns a new ``IRI``; keep the original when you pass the identifier on, as
RFC 3987 section 5.3.2.3 requires.

## Compare Exact Text

`==` compares the Unicode scalar sequences of two values. Use it at the I/O
boundary, for example to match an incoming identifier exactly before a
decoder turns it into a Swift type. An ``IRI`` is a boundary value, not a
term identity inside the runtime, so do not build registries or
dictionaries keyed by IRIs.

```swift
let lhs = try IRI(validating: "http://example.org/~user")
let rhs = try IRI(validating: "http://example.org/%7Euser")

lhs == rhs
// false
```

## Normalize the Generic Syntax

Syntax-based normalization applies rules that hold for every IRI:

- ``IRINormalization/letterCase`` lowercases the scheme and a host that is
  US-ASCII only, and uppercases the hex digits in percent-encodings.
- ``IRINormalization/percentEncoding`` decodes percent-encoded `iunreserved`
  characters, including UTF-8 encoded Unicode characters, so that
  `ros%C3%A9` and `rosé` match. Reserved characters such as `%2F` stay
  encoded.
- ``IRINormalization/pathSegments`` removes `.` and `..` segments with the
  `remove_dot_segments` algorithm of RFC 3986 section 5.2.4, exactly as
  written. The algorithm treats every path the same way, so a rootless path
  can become absolute: `foo:a/../b` becomes `foo:/b`, which is also what
  RFC 3986 section 5.2.2 gives when it resolves that IRI. When there is no
  authority and the result would begin with `//`, such as `//b` from
  `foo:a/../..//b`, the path is left as it is: RFC 3986 section 3.3 forbids
  such a path, because the text would read as an authority and name a
  different IRI, and RFC 3987 section 5.1 rules out that false positive.
  Section 5.1 allows the false negative that remains: `foo:/.//a/./b` and
  `foo:/.//a/b` are not equivalent.

```swift
let lhs = try IRI(validating: "example://a/b/c/%7Bfoo%7D/rosé")
let rhs = try IRI(validating: "eXAMPLE://a/./b/../b/%63/%7bfoo%7d/ros%C3%A9")

try rhs.normalized().rawValue
// "example://a/b/c/%7Bfoo%7D/rosé"

try lhs.isEquivalent(to: rhs)
// true
```

Pass a subset of steps when you need only some of them.

```swift
try IRI(validating: "HTTP://Example.com/a/../b").normalized(.letterCase).rawValue
// "http://example.com/a/../b"
```

## Normalize for a Scheme

Add ``IRINormalization/scheme`` when the scheme's own rules should apply.
IRIKit applies scheme-based normalization only to the schemes whose
specifications define a default port, an empty path that is equivalent to
`/`, and a required host:

| Scheme | Default port | Empty path | Specification |
| --- | --- | --- | --- |
| `http` | 80 | `/` | RFC 9110 section 4.2.1 (port, host required) and section 4.2.3 (normalization) |
| `https` | 443 | `/` | RFC 9110 section 4.2.2 (port, host required) and section 4.2.3 (normalization) |
| `ws` | 80 | `/` | RFC 6455 section 3: the port "is OPTIONAL; the default for "ws" is port 80", and the resource name is "/" if the path component is empty |
| `wss` | 443 | `/` | RFC 6455 section 3: "the default for "wss" is port 443" |
| `ftp` | 21 | `/` | RFC 1738 section 3.2: "If :<port> is omitted, the port defaults to 21"; section 3.1: the "/" between host and url-path is not part of the url-path, so an empty path and `/` give the same url-path; section 5: `ftpurl` requires a `hostport` |

For these schemes the default port and an empty port are removed, an empty
path becomes `/`, and a host is required. RFC 3986 section 3.2.3 defines the
port as a number in decimal, and each of these schemes uses it as a TCP port
number, so leading zeros are removed from the port first: `:0080` is the
default port and `:08080` becomes `:8080`.

```swift
let forms = ["http://example.com", "http://example.com:/", "http://example.com:80/"]

try forms.map { try IRI(validating: $0).normalized(.syntaxAndSchemeBased).rawValue }
// ["http://example.com/", "http://example.com/", "http://example.com/"]
```

An `http` IRI without a host cannot be normalized for its scheme, so the call
throws.

```swift
try IRI(validating: "https:/relative").normalized(.syntaxAndSchemeBased)
// Throws IRIError.invalidIRI("https:/relative")
```

### Internationalized Domain Names

RFC 3987 section 5.3.3 says IDN host names "SHOULD be validated by using the
ToASCII operation defined in [RFC3490]" and that validated IDN components
"SHOULD be character normalized by using the Nameprep process [RFC3491]".
IRIKit implements both, with the flags RFC 3987 section 3.1 sets for any use
other than creating an IRI (UseSTD3ASCIIRules TRUE, AllowUnassigned TRUE):

1. The host is split at the four label separators of RFC 3490 section 3.1:
   U+002E, U+3002 IDEOGRAPHIC FULL STOP, U+FF0E FULLWIDTH FULL STOP and
   U+FF61 HALFWIDTH IDEOGRAPHIC FULL STOP. A trailing empty label is the root
   label and is kept.
2. Each label goes through ToASCII (RFC 3490 section 4.1), which applies
   Nameprep: table B.1 characters are removed, table B.2 case-folds (so `ß`
   becomes `ss` and `ℌ` becomes `h`), the text is put in Normalization Form
   KC of Unicode 3.2, and output with a prohibited character (tables C.1.2,
   C.2.2 and C.3 to C.9) or that fails the bidi check of RFC 3454 section 6
   is rejected. The STD3 rules then reject any ASCII character other than
   letters, digits and `-`, and a leading or trailing `-`.
3. When every label passes, each label's normal form is ToUnicode of its
   ToASCII result (RFC 3490 section 4.2) with ASCII letters lowercased, and
   the labels are joined with `.`. The normal form stays legible Unicode
   rather than ACE. A label whose Unicode text could not stand in an IRI
   host keeps its lowercased ACE form.
4. When any label fails ToASCII the host is not a valid IDN, and it keeps
   its characters.

```swift
let unicode = try IRI(validating: "HTTPS://BÜCHER.Example:443/a/./b/../c")
let ace = try IRI(validating: "https://xn--bcher-kva.example/a/c")

try unicode.normalized(.syntaxAndSchemeBased).rawValue
// "https://bücher.example/a/c"

try unicode.isEquivalent(to: ace, under: .syntaxAndSchemeBased)
// true

try IRI(validating: "http://straße.example/").normalized(.syntaxAndSchemeBased).rawValue
// "http://strasse.example/"

try IRI(validating: "http://example。org/").normalized(.syntaxAndSchemeBased).rawValue
// "http://example.org/"
```

Two labels have the same normal form exactly when their ToASCII results are
equal ignoring ASCII case, which is how RFC 3490 section 3.1 says labels are
compared. The mapping is applied once: ToUnicode accepts a decoded label only
when ToASCII gives back the same ACE label, so normalizing a normal form
changes nothing. A label such as `google⒈com`, whose Nameprep output
contains a `.`, fails the STD3 rules, so `www.google⒈com` is not equivalent
to `www.google1.com`; this is one of the spoofing risks RFC 3987 section 8
describes.

Empty query and fragment delimiters are never removed:
`http://example.com/?` and `http://example.com/#` stay distinct from
`http://example.com/`.

## Opt In to Character Normalization

RFC 3987 says comparison must assume IRIs are already in a suitable Unicode
normalization form, so no preset applies Unicode normalization. Add
``IRINormalization/characters`` only when the text came from a non-digital
source or a non-Unicode encoding, where the RFC requires NFC.

```swift
let decomposed = try IRI(validating: "http://www.example.org/re\u{301}sume\u{301}.html")

try decomposed.normalized([.syntaxBased, .characters]).rawValue
// "http://www.example.org/résumé.html"
```

Character normalization never makes a valid IRI invalid. NFC runs on the
text between percent-encoded triplets, because a triplet stands for an octet
(RFC 3986 section 2.1), so a combining mark after a triplet does not compose
with its last hex digit. When NFC maps a character to one the component does
not allow, the result is percent-encoded as UTF-8, as RFC 3987 section 3.1
encodes any character that cannot appear literally. The only such character
in Unicode 17.0.0 is U+1FEF GREEK VARIA, whose canonical decomposition is the
grave accent U+0060.

```swift
try IRI(validating: "http://example.org/a\u{1FEF}").normalized(.characters).rawValue
// "http://example.org/a%60"
```

## Where the Unicode Data Comes From

IRIKit carries its own Unicode normalization, so normalization does not
depend on Foundation or on the Unicode version of the platform.
`Scripts/UnicodeTables/generate.py` writes the tables from the published
data, and `Scripts/UnicodeTables/sources.json` pins each input by URL and
SHA-256:

- Character normalization (NFC) uses the Unicode Character Database 17.0.0.
  Under the Unicode normalization stability policy, text whose characters
  are assigned in an earlier version has the same NFC form in every later
  version.
- Nameprep uses the Unicode Character Database 3.2.0 and the tables of
  RFC 3454 appendices B, C and D, because stringprep fixes Unicode 3.2
  (RFC 3454 section 4).

The test suite runs the Unicode conformance files `NormalizationTest.txt`
for both versions.

## Leave References to Their Context

Normalization is defined for ``IRI`` and ``AbsoluteIRI``. An ``IRIReference``
may be relative, and RFC 3987 section 5.1 compares references only after they
are resolved against a base IRI. IRIKit validates reference syntax and leaves
resolution to the surrounding document or application, so resolve the
reference first and then normalize the resulting ``IRI``.

Escaping that belongs to a format, such as XML entities or Turtle `\u`
escapes, is also resolved by that format's decoder before an ``IRI`` is
created (RFC 3987 section 5.2).
