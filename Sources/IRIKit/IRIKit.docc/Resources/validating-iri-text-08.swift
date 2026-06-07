import IRIKit

let fixed = try IRI("https://example.com/vocabulary/name" as StaticString)
let fixedReference = try IRIReference("#name" as StaticString)
let fixedTemplate = try IRITemplate("https://example.com/{term}" as StaticString)
