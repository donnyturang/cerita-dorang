#!/usr/bin/env python3
"""
Helper: strip tanda kutip & whitespace dari input.
Berguna untuk quote yang di-paste dari web / ketik manual.
"""
import sys

# Karakter yang dianggap tanda kutip
QUOTE_CHARS = (
    chr(34)    +  # " double quote lurus
    chr(39)    +  # ' single quote lurus
    chr(8220)  +  # " curly open
    chr(8221)  +  # " curly close
    chr(8216)  +  # ' curly open
    chr(8217)     # ' curly close
)


def strip_quotes(s):
    s = s.strip()
    while s and s[0] in QUOTE_CHARS:
        s = s[1:].strip()
    while s and s[-1] in QUOTE_CHARS:
        s = s[:-1].strip()
    return s


if __name__ == "__main__":
    text = sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read()
    print(strip_quotes(text))
