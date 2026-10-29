import Foundation

// Unicode normalization for RFC 3987 section 5.3.2.2 character
// normalization and IDN host mapping. The standard library has no public
// normalization API, so these come from Foundation and stay with the other
// Foundation bridging code.
extension String {
    /// The text in Normalization Form C.
    var canonicallyComposed: String {
        precomposedStringWithCanonicalMapping
    }

    /// The text in Normalization Form KC.
    var compatibilityComposed: String {
        precomposedStringWithCompatibilityMapping
    }
}
