#!/usr/bin/env python3
"""Reports the Part 8 anti-overengineering budgets and the Part 9.4 early-warning counts."""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PACKAGES = ROOT / "Packages"

PUBLIC_DECL = re.compile(
    r"^public\s+(?:final\s+)?(?:protocol|struct|class|enum|actor|func|let|var|typealias)\b"
)


def sources(package):
    return sorted((PACKAGES / package / "Sources").rglob("*.swift"))


def strip_comments(text):
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    lines = []
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("//"):
            continue
        lines.append(line)
    return lines


def public_symbols(package):
    found = []
    for path in sources(package):
        for line in path.read_text().splitlines():
            if line.startswith("public extension"):
                continue
            if PUBLIC_DECL.match(line):
                found.append((path.name, line.strip()))
    return found


def init_param_counts():
    worst = []
    for path in PACKAGES.rglob("Sources/**/*.swift"):
        text = path.read_text()
        for match in re.finditer(r"\binit\??\(", text):
            start = match.end()
            depth = 1
            index = start
            commas = 0
            while index < len(text) and depth > 0:
                char = text[index]
                if char in "([{":
                    depth += 1
                elif char in ")]}":
                    depth -= 1
                elif char == "," and depth == 1:
                    commas += 1
                index += 1
            body = text[start:index - 1].strip()
            count = 0 if not body else commas + 1
            worst.append((count, path.relative_to(ROOT)))
    worst.sort(reverse=True)
    return worst[:3]


def long_files():
    over200 = []
    for path in PACKAGES.rglob("Sources/**/*.swift"):
        count = len(strip_comments(path.read_text()))
        if count > 200:
            over200.append((count, path.relative_to(ROOT)))
    return sorted(over200, reverse=True)


def long_methods():
    over40 = []
    for path in PACKAGES.rglob("Sources/**/*.swift"):
        lines = path.read_text().splitlines()
        index = 0
        while index < len(lines):
            if re.search(r"\bfunc\s+\w+", lines[index]) and lines[index].rstrip().endswith("{"):
                depth = 1
                length = 0
                cursor = index + 1
                while cursor < len(lines) and depth > 0:
                    depth += lines[cursor].count("{") - lines[cursor].count("}")
                    if depth > 0:
                        stripped = lines[cursor].strip()
                        if stripped and not stripped.startswith("//"):
                            length += 1
                    cursor += 1
                if length > 40:
                    over40.append((length, path.relative_to(ROOT), lines[index].strip()))
                index = cursor
            else:
                index += 1
    return sorted(over40, reverse=True)


def long_identifiers():
    found = set()
    for path in PACKAGES.rglob("Sources/**/*.swift"):
        for match in re.finditer(r"\b(?:let|var|func)\s+([a-z]\w{30,})\b", path.read_text()):
            found.add(match.group(1))
    return sorted(found)


def main():
    router_files = sources("RouterKit")
    router_lines = sum(len(strip_comments(path.read_text())) for path in router_files)
    router_public = public_symbols("RouterKit")
    core_public = public_symbols("CoreKit")

    print("PART 8 BUDGETS")
    print(f"  RouterKit source files (excl. tests)   {len(router_files):>4}   limit 20")
    print(f"  RouterKit non-comment lines            {router_lines:>4}   limit 1500")
    print(f"  RouterKit public symbols               {len(router_public):>4}   limit 25")
    print(f"  CoreKit public symbols                 {len(core_public):>4}   limit 30")
    worst_init = init_param_counts()
    print(f"  Max parameters in any init             {worst_init[0][0]:>4}   limit 5"
          f"   ({worst_init[0][1]})")

    print("\nPART 9.4 EARLY WARNINGS")
    files = long_files()
    print(f"  Files over 200 non-comment lines       {len(files):>4}")
    for count, path in files:
        print(f"      {count:>4}  {path}")
    methods = long_methods()
    print(f"  Methods over 40 lines                  {len(methods):>4}")
    for length, path, signature in methods:
        print(f"      {length:>4}  {path}  {signature}")
    identifiers = long_identifiers()
    print(f"  Identifiers over 30 characters         {len(identifiers):>4}")
    for name in identifiers:
        print(f"      {name}")

    print("\nROUTERKIT PUBLIC SYMBOLS")
    for name, decl in router_public:
        print(f"  {name:<32} {decl}")

    failures = 0
    if len(router_files) > 20:
        failures += 1
    if router_lines > 1500:
        failures += 1
    if len(router_public) > 25:
        failures += 1
    if len(core_public) > 30:
        failures += 1
    if worst_init and worst_init[0][0] > 5:
        failures += 1
    print(f"\nbudget failures: {failures}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
