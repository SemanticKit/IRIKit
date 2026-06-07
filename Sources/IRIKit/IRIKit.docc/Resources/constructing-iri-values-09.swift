import IRIKit

let template = try IRITemplate(
    validating: "https://example.com/{collection}/{name}"
)

let expanded = try template.expand([
    "collection": "people",
    "name": "renée",
])

expanded.rawValue
// "https://example.com/people/renée"
