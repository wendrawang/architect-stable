#!/usr/bin/env python3
"""Applies the custom_rules regexes from .swiftlint.yml to Packages/*/Sources.

SwiftLint itself needs a Swift toolchain, which CI images for this repository have and a
plain Linux container does not. This script is a portable subset: it evaluates only the
regex-based custom rules, exactly as written in the config, so the house rules that are
pure text patterns can be checked anywhere. It is not a replacement for
`swiftlint --strict`; it does not evaluate any built-in rule.
"""
import pathlib
import re
import sys

import yaml

ROOT = pathlib.Path(__file__).resolve().parent.parent
CONFIG = yaml.safe_load((ROOT / ".swiftlint.yml").read_text())
RULES = CONFIG.get("custom_rules", {})

DISABLE_NEXT = re.compile(r"//\s*swiftlint:disable:next\s+([\w, ]+)")


def swift_sources():
    for package in sorted((ROOT / "Packages").iterdir()):
        sources = package / "Sources"
        if not sources.is_dir():
            continue
        for path in sorted(sources.rglob("*.swift")):
            yield path


def disabled_lines(text):
    """Maps line number -> set of rule ids suppressed by a disable:next on the line above."""
    suppressed = {}
    for index, line in enumerate(text.splitlines(), start=1):
        match = DISABLE_NEXT.search(line)
        if match:
            ids = {token.strip() for token in match.group(1).split(",") if token.strip()}
            suppressed[index + 1] = ids
    return suppressed


def main():
    violations = []
    for path in swift_sources():
        text = path.read_text()
        suppressed = disabled_lines(text)
        for rule_id, rule in RULES.items():
            pattern = re.compile(rule["regex"])
            for match in pattern.finditer(text):
                line = text.count("\n", 0, match.start()) + 1
                if rule_id in suppressed.get(line, set()):
                    continue
                snippet = match.group(0).strip().splitlines()[0]
                violations.append((path.relative_to(ROOT), line, rule_id,
                                   rule.get("severity", "warning"), snippet))
    for path, line, rule_id, severity, snippet in violations:
        print(f"{path}:{line}: {severity}: {rule_id}: {snippet}")
    print(f"\ncustom-rule violations: {len(violations)}")
    return 1 if violations else 0


if __name__ == "__main__":
    sys.exit(main())
