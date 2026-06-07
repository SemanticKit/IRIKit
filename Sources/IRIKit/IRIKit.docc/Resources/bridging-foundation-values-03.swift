import Foundation
import IRIKit

let reference = try IRIReference(validating: "../people/renée#summary")
let referenceURL = URL(reference)

referenceURL.relativeString
// "../people/ren%C3%A9e#summary"
