import IRIKit

let relative = try IRIReference(validating: "../people/renée#summary")
let fragment = try IRIReference(validating: "#summary")
