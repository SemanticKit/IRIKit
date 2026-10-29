#!/usr/bin/env python3
"""Generates IRIKit's Unicode normalization and stringprep tables.

IRIKit implements the specifications it cites instead of inventing data:

- Unicode Normalization Forms (UAX #15) for RFC 3987 section 5.3.2.2
  character normalization, from the Unicode Character Database 17.0.0.
- RFC 3491 Nameprep for RFC 3987 section 5.3.3 IDN normalization. Nameprep
  is the RFC 3454 stringprep profile, which fixes Unicode 3.2 for its
  normalization step and its tables, so it uses the Unicode Character
  Database 3.2.0 and the tables of RFC 3454 appendices B, C and D.

Every input is pinned by URL and SHA-256 in sources.json next to this script.
The script refuses an input whose digest differs, so a regenerated table
always comes from the recorded data.

Usage (from the package root):

    python3 Scripts/UnicodeTables/generate.py            # write the tables
    python3 Scripts/UnicodeTables/generate.py --check    # fail if out of date
    python3 Scripts/UnicodeTables/generate.py --crosscheck
        # also compare the parsed data with CPython's independently
        # generated unicodedata.ucd_3_2_0 and stringprep modules

Downloads are cached in .build/unicode-tables (ignored by git).
"""

import argparse
import hashlib
import json
import os
import sys
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
CACHE = os.path.join(ROOT, ".build", "unicode-tables")
SOURCES_DIR = os.path.join(ROOT, "Sources", "IRIKit", "Unicode")
TEST_RESOURCES = os.path.join(ROOT, "Tests", "IRIKitTests", "Resources")

HANGUL_S_BASE = 0xAC00
HANGUL_S_COUNT = 11172


# MARK: - Inputs


def load_sources():
    with open(os.path.join(HERE, "sources.json"), encoding="utf-8") as handle:
        return json.load(handle)


def fetch(url, sha256, name):
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, name)
    if not os.path.exists(path):
        with urllib.request.urlopen(url) as response:
            data = response.read()
        with open(path, "wb") as handle:
            handle.write(data)
    with open(path, "rb") as handle:
        data = handle.read()
    digest = hashlib.sha256(data).hexdigest()
    if digest != sha256:
        sys.exit(f"{name}: SHA-256 {digest} does not match the pinned {sha256} ({url})")
    return data.decode("utf-8")


def unicode_file(sources, version, name):
    entry = sources["unicode"][version]
    return fetch(entry["baseURL"] + name, entry["files"][name], f"{version}-{name}")


def code_points(field):
    """Parses `XXXX` or `XXXX..YYYY` into an inclusive range."""
    field = field.strip()
    if ".." in field:
        start, end = field.split("..")
        return int(start, 16), int(end, 16)
    value = int(field, 16)
    return value, value


# MARK: - Unicode Character Database


class UCD:
    def __init__(self, sources, version):
        self.version = version
        self.combining_class = {}
        self.decomposition = {}  # code point -> (is_compatibility, [code points])
        self.assigned = set()
        range_start = None
        for line in unicode_file(sources, version, "UnicodeData.txt").splitlines():
            fields = line.split(";")
            if len(fields) < 15:
                continue
            value = int(fields[0], 16)
            if fields[1].endswith(", First>"):
                range_start = value
            elif fields[1].endswith(", Last>"):
                self.assigned.update(range(range_start, value + 1))
            self.assigned.add(value)
            ccc = int(fields[3])
            if ccc:
                self.combining_class[value] = ccc
            mapping = fields[5].strip()
            if mapping:
                is_compatibility = mapping.startswith("<")
                if is_compatibility:
                    mapping = mapping.split(">", 1)[1]
                self.decomposition[value] = (is_compatibility, [int(part, 16) for part in mapping.split()])

        self.exclusions = set()
        for line in unicode_file(sources, version, "CompositionExclusions.txt").splitlines():
            line = line.split("#", 1)[0].strip()
            if line:
                start, end = code_points(line)
                self.exclusions.update(range(start, end + 1))

        self.derived_full_exclusion = set()
        for line in unicode_file(sources, version, "DerivedNormalizationProps.txt").splitlines():
            data = line.split("#", 1)[0]
            if not data.strip():
                continue
            fields = [field.strip() for field in data.split(";")]
            if len(fields) >= 2 and fields[1] == "Full_Composition_Exclusion":
                start, end = code_points(fields[0])
                self.derived_full_exclusion.update(range(start, end + 1))

    def assigned_planes(self):
        """The planes that hold an assigned code point other than private use."""
        planes = set()
        for value in self.assigned:
            if not (0xE000 <= value <= 0xF8FF or value >= 0xF0000):
                planes.add(value >> 16)
        return planes

    def full_decomposition(self, value, compatibility):
        """The recursive decomposition (UAX #15 D68 and D65)."""
        entry = self.decomposition.get(value)
        if entry is None or (entry[0] and not compatibility):
            return [value]
        result = []
        for part in entry[1]:
            result.extend(self.full_decomposition(part, compatibility))
        return result

    def full_composition_exclusions(self):
        """UAX #15 Full_Composition_Exclusion, derived from its definition:
        the listed exclusions, singletons, and non-starter decompositions."""
        excluded = set(self.exclusions)
        for value, (is_compatibility, mapping) in self.decomposition.items():
            if is_compatibility:
                continue
            if len(mapping) == 1:
                excluded.add(value)
            elif self.combining_class.get(value, 0) or self.combining_class.get(mapping[0], 0):
                excluded.add(value)
        return excluded

    def tables(self, include_compatibility):
        combining = []
        for value in sorted(self.combining_class):
            ccc = self.combining_class[value]
            if combining and combining[-1][1] == value - 1 and combining[-1][2] == ccc:
                combining[-1][1] = value
            else:
                combining.append([value, value, ccc])

        canonical = {}
        compatibility = {}
        for value in sorted(self.decomposition):
            if HANGUL_S_BASE <= value < HANGUL_S_BASE + HANGUL_S_COUNT:
                continue
            nfd = self.full_decomposition(value, False)
            if nfd != [value]:
                canonical[value] = nfd
            if include_compatibility:
                nfkd = self.full_decomposition(value, True)
                if nfkd != nfd:
                    compatibility[value] = nfkd

        for mapping in canonical.values():
            if any(HANGUL_S_BASE <= part < HANGUL_S_BASE + HANGUL_S_COUNT for part in mapping):
                sys.exit(f"Unicode {self.version}: a decomposition holds a Hangul syllable")
        for mapping in compatibility.values():
            if any(HANGUL_S_BASE <= part < HANGUL_S_BASE + HANGUL_S_COUNT for part in mapping):
                sys.exit(f"Unicode {self.version}: a decomposition holds a Hangul syllable")

        excluded = self.full_composition_exclusions()
        if excluded != self.derived_full_exclusion:
            sys.exit(
                f"Unicode {self.version}: derived composition exclusions differ from "
                f"DerivedNormalizationProps.txt by {sorted(excluded ^ self.derived_full_exclusion)[:10]}"
            )
        compositions = []
        for value in sorted(self.decomposition):
            is_compatibility, mapping = self.decomposition[value]
            if not is_compatibility and len(mapping) == 2 and value not in excluded:
                compositions.append((mapping[0], mapping[1], value))
        return combining, canonical, compatibility, compositions


# MARK: - RFC 3454


def rfc3454_tables(sources):
    entry = sources["rfc3454"]
    text = fetch(entry["url"], entry["sha256"], "rfc3454.txt")
    tables = {}
    current = None
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("----- Start Table "):
            current = stripped[len("----- Start Table "):].split()[0]
            tables[current] = []
        elif stripped.startswith("----- End Table "):
            current = None
        elif current and stripped:
            tables[current].append(stripped)

    def ranges(name):
        result = []
        for line in tables[name]:
            field = line.split(";", 1)[0].strip()
            if "-" in field:
                start, end = field.split("-")
                result.append((int(start, 16), int(end, 16)))
            else:
                result.append((int(field, 16), int(field, 16)))
        return result

    def mappings(name):
        result = {}
        for line in tables[name]:
            fields = [field.strip() for field in line.split(";")]
            result[int(fields[0], 16)] = [int(part, 16) for part in fields[1].split()]
        return result

    return tables, ranges, mappings


def merged(ranges):
    result = []
    for start, end in sorted(ranges):
        if result and start <= result[-1][1] + 1:
            result[-1][1] = max(result[-1][1], end)
        else:
            result.append([start, end])
    return result


# MARK: - Swift output


def swift_array(values, indent="        "):
    lines = []
    for index in range(0, len(values), 8):
        chunk = values[index:index + 8]
        lines.append(indent + ", ".join(f"0x{value:06X}" for value in chunk) + ",")
    return "\n".join(lines)


def header(sources, inputs):
    lines = [
        "// This file is generated by Scripts/UnicodeTables/generate.py. Do not edit it.",
        "//",
        "// Inputs, pinned by SHA-256 in Scripts/UnicodeTables/sources.json:",
    ]
    for description, url, digest in inputs:
        lines.append(f"// - {description}")
        lines.append(f"//   {url}")
        lines.append(f"//   SHA-256 {digest}")
    return "\n".join(lines) + "\n"


def flatten_mappings(mapping):
    """Records of a header word (code point | length << 21) followed by the
    mapped code points."""
    result = []
    for value in sorted(mapping):
        target = mapping[value]
        if len(target) >= 1 << 11:
            sys.exit("mapping too long")
        result.append(value | (len(target) << 21))
        result.extend(target)
    return result


def normalization_source(sources, ucd, name, include_compatibility):
    combining, canonical, compatibility, compositions = ucd.tables(include_compatibility)
    entry = sources["unicode"][ucd.version]
    inputs = [
        (f"Unicode {ucd.version} {file}", entry["baseURL"] + file, entry["files"][file])
        for file in ("UnicodeData.txt", "CompositionExclusions.txt", "DerivedNormalizationProps.txt")
    ]
    flat_combining = [value for triple in combining for value in triple]
    flat_compositions = [value for triple in compositions for value in triple]
    version_label = ucd.version
    out = [header(sources, inputs)]
    out.append("extension UnicodeNormalizationData {")
    out.append(f"    /// The Unicode {version_label} normalization data (UAX #15).")
    out.append(f"    static let {name} = UnicodeNormalizationData(")
    out.append(f'        version: "{version_label}",')
    out.append(f"        combiningClassRanges: {name}CombiningClassRanges,")
    out.append(f"        canonicalDecompositions: {name}CanonicalDecompositions,")
    out.append(f"        compatibilityDecompositions: {name}CompatibilityDecompositions,")
    out.append(f"        primaryComposites: {name}PrimaryComposites")
    out.append("    )")
    out.append("")

    def array(label, comment, values):
        out.append(f"    /// {comment}")
        if values:
            out.append(f"    private static let {name}{label}: [UInt32] = [")
            out.append(swift_array(values))
            out.append("    ]")
        else:
            out.append(f"    private static let {name}{label}: [UInt32] = []")
        out.append("")

    array(
        "CombiningClassRanges",
        "Triples of first code point, last code point and canonical combining class, for every nonzero class.",
        flat_combining,
    )
    array(
        "CanonicalDecompositions",
        "Full canonical decompositions (D68), as a header word (code point | count << 21) and the mapped code points. Hangul syllables are decomposed algorithmically.",
        flatten_mappings(canonical),
    )
    array(
        "CompatibilityDecompositions",
        "Full compatibility decompositions (D65) of the code points whose compatibility decomposition differs from their canonical one, in the same layout.",
        flatten_mappings(compatibility),
    )
    array(
        "PrimaryComposites",
        "Triples of first code point, second code point and primary composite (D114), excluding Full_Composition_Exclusion.",
        flat_compositions,
    )
    out[-1:] = []
    out.append("}")
    return "\n".join(out) + "\n", (combining, canonical, compatibility, compositions)


NAMEPREP_PROHIBITED = ["C.1.2", "C.2.2", "C.3", "C.4", "C.5", "C.6", "C.7", "C.8", "C.9"]


def stringprep_source(sources, ranges, mappings):
    entry = sources["rfc3454"]
    inputs = [("RFC 3454 appendices A to D", entry["url"], entry["sha256"])]
    b1 = [start for start, end in ranges("B.1") for start in range(start, end + 1)]
    b2 = mappings("B.2")
    prohibited = merged([r for name in NAMEPREP_PROHIBITED for r in ranges(name)])
    d1 = merged(ranges("D.1"))
    d2 = merged(ranges("D.2"))

    out = [header(sources, inputs)]
    out.append("extension Nameprep {")

    def array(label, comment, values):
        out.append(f"    /// {comment}")
        out.append(f"    static let {label}: [UInt32] = [")
        out.append(swift_array(values, indent="        "))
        out.append("    ]")
        out.append("")

    array("mappedToNothing", "RFC 3454 table B.1: code points commonly mapped to nothing.", b1)
    array(
        "caseFoldingForNFKC",
        "RFC 3454 table B.2: mapping for case-folding used with NFKC, as a header word (code point | count << 21) and the mapped code points.",
        flatten_mappings(b2),
    )
    array(
        "prohibitedRanges",
        "RFC 3491 section 5 prohibited output: RFC 3454 tables " + ", ".join(NAMEPREP_PROHIBITED) + ", as pairs of first and last code point.",
        [value for pair in prohibited for value in pair],
    )
    array(
        "randALCatRanges",
        "RFC 3454 table D.1: characters with bidirectional property R or AL, as pairs of first and last code point.",
        [value for pair in d1 for value in pair],
    )
    array(
        "lCatRanges",
        "RFC 3454 table D.2: characters with bidirectional property L, as pairs of first and last code point.",
        [value for pair in d2 for value in pair],
    )
    out[-1:] = []
    out.append("}")
    return "\n".join(out) + "\n", (b1, b2, prohibited, d1, d2)


# MARK: - Cross-check


def crosscheck(ucd32, b1, b2, prohibited, ranges):
    import collections
    import stringprep
    import unicodedata

    old = unicodedata.ucd_3_2_0
    members = {
        name: {v for start, end in ranges(name) for v in range(start, end + 1)}
        for name in NAMEPREP_PROHIBITED + ["D.1", "D.2"]
    }
    prohibited_set = {v for start, end in prohibited for v in range(start, end + 1)}
    predicates = {
        "C.1.2": stringprep.in_table_c12, "C.2.2": stringprep.in_table_c22,
        "C.3": stringprep.in_table_c3, "C.4": stringprep.in_table_c4,
        "C.5": stringprep.in_table_c5, "C.6": stringprep.in_table_c6,
        "C.7": stringprep.in_table_c7, "C.8": stringprep.in_table_c8,
        "C.9": stringprep.in_table_c9, "D.1": stringprep.in_table_d1,
        "D.2": stringprep.in_table_d2,
    }
    failures = collections.Counter()
    examples = {}

    def fail(kind, value):
        failures[kind] += 1
        examples.setdefault(kind, value)

    for value in range(0x110000):
        if 0xD800 <= value <= 0xDFFF:
            continue
        char = chr(value)
        if not HANGUL_S_BASE <= value < HANGUL_S_BASE + HANGUL_S_COUNT:
            for form, compatibility in (("NFD", False), ("NFKD", True)):
                expected = [ord(part) for part in old.normalize(form, char)]
                if ucd32.full_decomposition(value, compatibility) != expected:
                    fail(form, value)
        if old.combining(char) != ucd32.combining_class.get(value, 0):
            fail("combining class", value)
        if (value in b1) != stringprep.in_table_b1(char):
            fail("B.1", value)
        mapped = "".join(chr(part) for part in b2.get(value, [value]))
        if mapped != stringprep.map_table_b2(char):
            fail("B.2", value)
        for name, predicate in predicates.items():
            if (value in members[name]) != predicate(char):
                fail(name, value)
        if (value in prohibited_set) != any(predicates[name](char) for name in NAMEPREP_PROHIBITED):
            fail("prohibited", value)
    if failures:
        detail = ", ".join(f"{kind}: {count} (first U+{examples[kind]:04X})" for kind, count in failures.items())
        sys.exit(f"cross-check: differences from CPython unicodedata.ucd_3_2_0 and stringprep: {detail}")
    print("cross-check: Unicode 3.2.0 full canonical and compatibility decompositions and combining classes, and RFC 3454 tables "
          "B.1, B.2, C.1.2 to C.9, D.1 and D.2 match CPython for all code points")


# MARK: - Main


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="fail when a generated file is out of date")
    parser.add_argument("--crosscheck", action="store_true", help="compare with CPython's modules")
    arguments = parser.parse_args()

    sources = load_sources()
    ucd17 = UCD(sources, "17.0.0")
    ucd32 = UCD(sources, "3.2.0")
    # Tests/IRIKitTests/RFC3987/Section5IDNHostNormalizationTests.swift
    # checks every code point of these planes exhaustively.
    if ucd32.assigned_planes() != {0x0, 0x1, 0x2, 0xE}:
        sys.exit(f"Unicode 3.2.0 assigns characters in planes {sorted(ucd32.assigned_planes())}")
    _, ranges, mappings = rfc3454_tables(sources)

    outputs = {}
    text17, _ = normalization_source(sources, ucd17, "unicode17_0", include_compatibility=True)
    outputs[os.path.join(SOURCES_DIR, "UnicodeNormalizationData+Unicode17.swift")] = text17
    text32, _ = normalization_source(sources, ucd32, "unicode3_2", include_compatibility=True)
    outputs[os.path.join(SOURCES_DIR, "UnicodeNormalizationData+Unicode3_2.swift")] = text32
    textprep, (b1, b2, prohibited, d1, d2) = stringprep_source(sources, ranges, mappings)
    outputs[os.path.join(SOURCES_DIR, "Nameprep+RFC3454Tables.swift")] = textprep
    for version in ("3.2.0", "17.0.0"):
        outputs[os.path.join(TEST_RESOURCES, f"NormalizationTest-{version}.txt")] = unicode_file(
            sources, version, "NormalizationTest.txt"
        )

    stale = []
    for path, text in outputs.items():
        current = None
        if os.path.exists(path):
            with open(path, encoding="utf-8") as handle:
                current = handle.read()
        if current != text:
            stale.append(os.path.relpath(path, ROOT))
            if not arguments.check:
                os.makedirs(os.path.dirname(path), exist_ok=True)
                with open(path, "w", encoding="utf-8", newline="\n") as handle:
                    handle.write(text)
    if arguments.check and stale:
        sys.exit("out of date: " + ", ".join(stale))
    print("up to date" if not stale else "wrote " + ", ".join(stale))

    if arguments.crosscheck:
        crosscheck(ucd32, set(b1), b2, prohibited, ranges)


if __name__ == "__main__":
    main()
