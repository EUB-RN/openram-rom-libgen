#!/usr/bin/env python3
"""
A small, dependency-free Liberty parser.

WHY THIS EXISTS: until now nothing in the flow ever read a generated .lib back.
gen_rom_lib.py writes text, and the first tool to parse it was whatever the
user pointed at the file -- so a missing brace or a table with the wrong number
of rows only ever surfaced downstream. This parser is deliberately strict and
reports a line number for everything it rejects.

It is NOT a full Liberty implementation and does not try to be. It covers the
syntax gen_rom_lib.py emits, which is the syntax that has to stay correct:

    group      :  IDENT '(' args ')' '{' statement* '}'
    complex    :  IDENT '(' args ')' ';'
    simple     :  IDENT ':' value ';'

plus /* */ comments and backslash line continuations.

Use `parse_file(path)` -> Group, or run it directly to dump a tree:

    python3 tests/libparse.py output/lib/wrom0_TT_1p8V_25C.lib
"""

from __future__ import annotations

import re
import sys


class LibertyError(Exception):
    """A syntax error, carrying the line number it was found on."""

    def __init__(self, msg, line):
        super().__init__("line %d: %s" % (line, msg))
        self.line = line
        self.msg = msg


class Group:
    """One Liberty group: `name (args) { ... }`."""

    __slots__ = ("name", "args", "line", "groups", "attrs")

    def __init__(self, name, args, line):
        self.name = name
        self.args = args            # list[str], quotes stripped
        self.line = line
        self.groups = []            # list[Group]
        self.attrs = []             # list[(name, value_or_args, line, kind)]

    # -- lookup helpers; the checks read much better with these ------------
    def find(self, name):
        """Every direct child group with this name."""
        return [g for g in self.groups if g.name == name]

    def first(self, name):
        for g in self.groups:
            if g.name == name:
                return g
        return None

    def descend(self, name):
        """Every group with this name at any depth."""
        out = []
        for g in self.groups:
            if g.name == name:
                out.append(g)
            out.extend(g.descend(name))
        return out

    def attr(self, name):
        """Value of the first simple attribute with this name, else None."""
        for aname, val, _line, kind in self.attrs:
            if aname == name and kind == "simple":
                return val
        return None

    def complex_args(self, name):
        """Args of the first complex attribute with this name, else None."""
        for aname, val, _line, kind in self.attrs:
            if aname == name and kind == "complex":
                return val
        return None

    def attr_line(self, name):
        for aname, _val, line, _kind in self.attrs:
            if aname == name:
                return line
        return self.line

    def label(self):
        return "%s(%s)" % (self.name, ",".join(self.args)) if self.args else self.name

    def __repr__(self):
        return "<Group %s at line %d>" % (self.label(), self.line)


# ---------------------------------------------------------------------------
# lexer
# ---------------------------------------------------------------------------

def _strip_comments(text):
    """Blank out /* */ comments but keep every newline, so lines still count."""
    out = []
    i = 0
    n = len(text)
    while i < n:
        if text.startswith("/*", i):
            j = text.find("*/", i + 2)
            if j < 0:
                raise LibertyError("unterminated /* comment",
                                   text.count("\n", 0, i) + 1)
            # keep the newlines, drop everything else
            out.append("\n" * text.count("\n", i, j + 2))
            i = j + 2
        else:
            out.append(text[i])
            i += 1
    return "".join(out)


_TOKEN = re.compile(r"""
      (?P<ws>\s+)
    | (?P<cont>\\\n)
    | (?P<str>"[^"]*")
    | (?P<punct>[(){}:;,])
    | (?P<ident>[A-Za-z0-9_.+\-*/\[\]!&|~^ ]+?)(?=[(){}:;,"\s])
""", re.X)


def _tokens(text):
    """Yield (kind, value, line). Whitespace and continuations are dropped."""
    line = 1
    i = 0
    n = len(text)
    while i < n:
        m = _TOKEN.match(text, i)
        if not m:
            raise LibertyError("cannot tokenize %r" % text[i:i + 20], line)
        kind = m.lastgroup
        val = m.group()
        line += val.count("\n")
        i = m.end()
        if kind in ("ws", "cont"):
            continue
        if kind == "str":
            yield ("str", val[1:-1], line)
        elif kind == "punct":
            yield (val, val, line)
        else:
            yield ("ident", val.strip(), line)


# ---------------------------------------------------------------------------
# parser
# ---------------------------------------------------------------------------

class _Parser:
    def __init__(self, text):
        self.toks = list(_tokens(text))
        self.i = 0

    def peek(self, k=0):
        j = self.i + k
        return self.toks[j] if j < len(self.toks) else ("eof", "", self.line())

    def line(self):
        if not self.toks:
            return 1
        j = min(self.i, len(self.toks) - 1)
        return self.toks[j][2]

    def take(self, kind=None):
        if self.i >= len(self.toks):
            raise LibertyError("unexpected end of file", self.line())
        tok = self.toks[self.i]
        if kind and tok[0] != kind:
            raise LibertyError("expected %r, found %r" % (kind, tok[1]), tok[2])
        self.i += 1
        return tok

    def args(self):
        """Consume '(' ... ')' and return the arguments as strings.

        Tokens inside one argument are glued back together, because a bus
        slice such as pin(dout0[31:0]) lexes as three tokens around the ':'.
        """
        self.take("(")
        out = []
        cur = []
        while self.peek()[0] != ")":
            kind, val, ln = self.take()
            if kind == ",":
                if cur:
                    out.append("".join(cur))
                    cur = []
                continue
            if kind in ("{", "}", ";", "eof"):
                raise LibertyError("argument list is never closed", ln)
            cur.append(val)
        if cur:
            out.append("".join(cur))
        self.take(")")
        return out

    def statements(self, parent):
        while True:
            kind, val, ln = self.peek()
            if kind == "}" or kind == "eof":
                return
            if kind != "ident":
                raise LibertyError("expected a name, found %r" % val, ln)
            self.take("ident")
            nxt = self.peek()[0]

            if nxt == ":":                              # simple attribute
                self.take(":")
                parts = []
                while self.peek()[0] not in (";", "}", "eof"):
                    parts.append(self.take()[1])
                if self.peek()[0] == ";":
                    self.take(";")
                parent.attrs.append((val, " ".join(parts), ln, "simple"))

            elif nxt == "(":                            # complex or group
                args = self.args()
                if self.peek()[0] == "{":
                    self.take("{")
                    g = Group(val, args, ln)
                    self.statements(g)
                    if self.peek()[0] != "}":
                        raise LibertyError("group %s opened here is never closed"
                                           % val, ln)
                    self.take("}")
                    parent.groups.append(g)
                else:
                    if self.peek()[0] == ";":
                        self.take(";")
                    parent.attrs.append((val, args, ln, "complex"))

            elif nxt == ";":
                self.take(";")
                parent.attrs.append((val, "", ln, "simple"))
            else:
                raise LibertyError("expected ':' or '(' after %r, found %r"
                                   % (val, self.peek()[1]), ln)


def parse(text):
    """Parse Liberty source and return the top-level `library` group."""
    p = _Parser(_strip_comments(text))
    root = Group("<file>", [], 0)
    p.statements(root)
    if p.peek()[0] != "eof":
        raise LibertyError("stray %r after the last group" % p.peek()[1],
                           p.peek()[2])
    libs = root.find("library")
    if len(libs) != 1:
        raise LibertyError("expected exactly one library group, found %d"
                           % len(libs), 1)
    return libs[0]


def parse_file(path):
    with open(path) as fh:
        return parse(fh.read())


if __name__ == "__main__":
    def dump(g, depth=0):
        print("  " * depth + g.label())
        for name, val, _ln, kind in g.attrs:
            shown = val if kind == "simple" else "(%s)" % ", ".join(val)
            print("  " * (depth + 1) + "%s = %s" % (name, shown[:70]))
        for child in g.groups:
            dump(child, depth + 1)

    for arg in sys.argv[1:]:
        try:
            dump(parse_file(arg))
        except LibertyError as exc:
            sys.exit("%s: %s" % (arg, exc))
