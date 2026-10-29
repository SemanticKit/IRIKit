/// A failure produced while validating or expanding an IRI value.
public enum IRIError: Error, Equatable, Sendable {
    /// The supplied string is not an absolute RFC 3987 IRI.
    case invalidIRI(String)

    /// The supplied string is not an RFC 3987 IRI reference.
    case invalidIRIReference(String)

    /// The template references a variable that was not supplied.
    case missingTemplateValue(String)

    /// The template syntax is invalid.
    case invalidTemplate(String)

    /// The normal form of the IRI cannot be written as IRI text.
    ///
    /// RFC 3986 section 5.2.4 `remove_dot_segments` can turn a path such as
    /// `/.//a` into `//a`. When the IRI has no authority, RFC 3986
    /// section 3.3 forbids that path, because the text would read as an
    /// authority. Comparison still works for such an IRI: `isEquivalent`
    /// compares normalized components, not text. The associated value is
    /// the original IRI.
    case normalFormHasNoText(String)
}
