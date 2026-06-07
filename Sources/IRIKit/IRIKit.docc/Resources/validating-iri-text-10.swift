import IRIKit

do {
    _ = try IRI(validating: "1https://example.com")
} catch IRIError.invalidIRI(let text) {
    print("Invalid IRI: \(text)")
}
