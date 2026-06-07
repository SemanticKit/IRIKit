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
}
