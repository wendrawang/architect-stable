#!/usr/bin/env python3
"""Structurally validates an Xcode project file without Xcode.

`project.pbxproj` is an OpenStep ASCII plist, which Python's plistlib cannot read. This
parses that subset and then checks the things a hand-written project gets wrong: unbalanced
delimiters, a missing semicolon, and above all a reference to an object id that does not
exist. Xcode reports those as "cannot be opened", with no line number.
"""
import pathlib
import re
import sys

COMMENT = re.compile(r"/\*.*?\*/", re.S)
LINE_COMMENT = re.compile(r"^\s*//.*$", re.M)
TOKEN = re.compile(r'"(?:[^"\\]|\\.)*"|[A-Za-z0-9_./$:+@~<>-]+|[{}()=;,]')
OBJECT_ID = re.compile(r"^[0-9A-F]{24}$")


def tokenize(text):
    text = LINE_COMMENT.sub("", COMMENT.sub(" ", text))
    return TOKEN.findall(text)


class Parser:
    def __init__(self, tokens):
        self.tokens = tokens
        self.index = 0

    def peek(self):
        return self.tokens[self.index] if self.index < len(self.tokens) else None

    def take(self):
        token = self.peek()
        if token is None:
            raise ValueError("unexpected end of file")
        self.index += 1
        return token

    def expect(self, token):
        actual = self.take()
        if actual != token:
            raise ValueError(f"expected {token!r} at token {self.index}, found {actual!r}")

    def parse_value(self):
        token = self.peek()
        if token == "{":
            return self.parse_dict()
        if token == "(":
            return self.parse_array()
        return self.take().strip('"')

    def parse_dict(self):
        self.expect("{")
        result = {}
        while self.peek() != "}":
            key = self.take().strip('"')
            self.expect("=")
            result[key] = self.parse_value()
            self.expect(";")
        self.expect("}")
        return result

    def parse_array(self):
        self.expect("(")
        items = []
        while self.peek() != ")":
            items.append(self.parse_value())
            if self.peek() == ",":
                self.take()
        self.expect(")")
        return items


def collect_ids(node, found):
    if isinstance(node, dict):
        for key, value in node.items():
            if OBJECT_ID.match(key):
                found.add(key)
            collect_ids(value, found)
    elif isinstance(node, list):
        for item in node:
            collect_ids(item, found)
    elif isinstance(node, str) and OBJECT_ID.match(node):
        found.add(node)


def main():
    path = pathlib.Path(sys.argv[1] if len(sys.argv) > 1
                        else "HostApp/HostApp.xcodeproj/project.pbxproj")
    parser = Parser(tokenize(path.read_text()))
    root = parser.parse_dict()
    objects = root["objects"]
    problems = []

    referenced = set()
    collect_ids(root, referenced)
    declared = set(objects)
    for identifier in sorted(referenced - declared):
        problems.append(f"reference to undeclared object {identifier}")
    for identifier in sorted(declared - referenced - {root["rootObject"]}):
        problems.append(f"object {identifier} is declared but never referenced")

    if root["rootObject"] not in objects:
        problems.append("rootObject is not in objects")
    project = objects.get(root["rootObject"], {})
    if project.get("isa") != "PBXProject":
        problems.append("rootObject is not a PBXProject")

    targets = project.get("targets", [])
    if not targets:
        problems.append("the project declares no targets")
    for identifier in targets:
        target = objects.get(identifier, {})
        for phase in target.get("buildPhases", []):
            if phase not in objects:
                problems.append(f"target {target.get('name')} references missing phase {phase}")
        for product in target.get("packageProductDependencies", []):
            if objects.get(product, {}).get("isa") != "XCSwiftPackageProductDependency":
                problems.append(f"bad package product dependency {product}")

    for identifier, obj in objects.items():
        if not isinstance(obj, dict) or "isa" not in obj:
            problems.append(f"object {identifier} has no isa")

    print(f"{path}: {len(objects)} objects, {len(targets)} target(s)")
    for name in sorted({obj.get("isa") for obj in objects.values() if isinstance(obj, dict)}):
        print(f"  {name}")
    for problem in problems:
        print(f"  PROBLEM: {problem}")
    print(f"pbxproj problems: {len(problems)}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
