import IRIKit

let template = try IRITemplate(validating: "https://example.com/{term}")

do {
    _ = try template.expand([:])
} catch IRIError.missingTemplateValue(let name) {
    print("Missing template value: \(name)")
}
