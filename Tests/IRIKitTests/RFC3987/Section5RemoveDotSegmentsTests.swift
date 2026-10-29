@testable import IRIKit
import Testing

extension RFC3987ComplianceTests {
    /// RFC 3987 section 5.3.2.4 normalizes path segments with the
    /// `remove_dot_segments` algorithm of RFC 3986 section 5.2.4.
    @Suite("Section 5.3.2.4 path segment normalization with RFC 3986 remove_dot_segments")
    struct Section5RemoveDotSegmentsTests {
        @Test(
            "remove_dot_segments gives the results of the two worked examples in RFC 3986 section 5.2.4.",
            .tags(.normalization),
            arguments: [
                ("/a/b/c/./../../g", "/a/g"),
                ("mid/content=5/../6", "mid/6"),
            ]
        )
        func section524Examples(_ input: String, _ expected: String) {
            #expect(IRINormalizer.removingDotSegments(from: input) == expected)
        }

        /// The examples of RFC 3986 sections 5.4.1 and 5.4.2, resolved
        /// against the base `http://a/b/c/d;p?q`. Each input is the path that
        /// section 5.2.2 passes to remove_dot_segments: the reference path
        /// merged with the base path (section 5.2.3), or the reference path
        /// itself when it is absolute. Each expected value is the path of the
        /// target URI the RFC lists.
        static let section54Cases: [(reference: String, input: String, expected: String)] = [
            // 5.4.1 Normal Examples
            ("g", "/b/c/g", "/b/c/g"),
            ("./g", "/b/c/./g", "/b/c/g"),
            ("g/", "/b/c/g/", "/b/c/g/"),
            ("/g", "/g", "/g"),
            (";x", "/b/c/;x", "/b/c/;x"),
            ("g;x", "/b/c/g;x", "/b/c/g;x"),
            (".", "/b/c/.", "/b/c/"),
            ("./", "/b/c/./", "/b/c/"),
            ("..", "/b/c/..", "/b/"),
            ("../", "/b/c/../", "/b/"),
            ("../g", "/b/c/../g", "/b/g"),
            ("../..", "/b/c/../..", "/"),
            ("../../", "/b/c/../../", "/"),
            ("../../g", "/b/c/../../g", "/g"),
            // 5.4.2 Abnormal Examples
            ("../../../g", "/b/c/../../../g", "/g"),
            ("../../../../g", "/b/c/../../../../g", "/g"),
            ("/./g", "/./g", "/g"),
            ("/../g", "/../g", "/g"),
            ("g.", "/b/c/g.", "/b/c/g."),
            (".g", "/b/c/.g", "/b/c/.g"),
            ("g..", "/b/c/g..", "/b/c/g.."),
            ("..g", "/b/c/..g", "/b/c/..g"),
            ("./../g", "/b/c/./../g", "/b/g"),
            ("./g/.", "/b/c/./g/.", "/b/c/g/"),
            ("g/./h", "/b/c/g/./h", "/b/c/g/h"),
            ("g/../h", "/b/c/g/../h", "/b/c/h"),
            ("g;x=1/./y", "/b/c/g;x=1/./y", "/b/c/g;x=1/y"),
            ("g;x=1/../y", "/b/c/g;x=1/../y", "/b/c/y"),
        ]

        @Test(
            "remove_dot_segments gives the paths of the RFC 3986 section 5.4 reference resolution examples.",
            .tags(.normalization),
            arguments: section54Cases
        )
        func section54Examples(_ example: (reference: String, input: String, expected: String)) {
            #expect(IRINormalizer.removingDotSegments(from: example.input) == example.expected, "reference \(example.reference)")
        }

        @Test(
            "remove_dot_segments runs on rootless paths exactly as written.",
            .tags(.normalization),
            arguments: [
                // 2E moves "a"; 2C then replaces "/../b" with "/b" and removes
                // "a", and 2E moves "/b".
                ("a/../b", "/b"),
                ("a/..", "/"),
                ("../a", "a"),
                ("./a", "a"),
                (".//b", "/b"),
                ("a/../..//b", "//b"),
                ("a/b/../c", "a/c"),
            ]
        )
        func rootlessPaths(_ input: String, _ expected: String) {
            #expect(IRINormalizer.removingDotSegments(from: input) == expected)
        }

        @Test(
            "remove_dot_segments reads characters, so a combining mark after / or . does not hide a segment boundary.",
            .tags(.normalization),
            arguments: [
                ("/a/\u{301}b/../c", "/a/c"),
                ("/a/.\u{301}/b", "/a/.\u{301}/b"),
                ("/a/..\u{301}/b", "/a/..\u{301}/b"),
                ("/\u{301}/../c", "/c"),
            ]
        )
        func combiningMarks(_ input: String, _ expected: String) {
            let result = IRINormalizer.removingDotSegments(from: input)
            #expect(result.unicodeScalars.elementsEqual(expected.unicodeScalars))
        }
    }
}
