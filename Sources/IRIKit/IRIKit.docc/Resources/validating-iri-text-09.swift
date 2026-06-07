import IRIKit

let line = "identifier=https://example.com/vocabulary/name"
let separator = line.firstIndex(of: "=")!

let sliced = try IRI(line[line.index(after: separator)...])
