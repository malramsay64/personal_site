"""Check Markdown files with a local LanguageTool server and print reviewdog rdjsonl.

Usage: python3 check.py FILE... | reviewdog -f=rdjsonl ...

Code, maths, links, HTML, Tera and front matter are blanked out (replaced by
spaces, keeping newlines) before checking, so reported offsets still map onto
the original file.
"""

import json
import os
import re
import sys
import urllib.parse
import urllib.request

SERVER = os.environ.get("LANGUAGETOOL_URL", "http://localhost:8081")
LANGUAGE = os.environ.get("LANGUAGETOOL_LANGUAGE", "en-AU")
WORDS_FILE = os.path.join(os.path.dirname(__file__), "words.txt")

# Rules that are noise for Markdown with semantic line breaks and blanked-out code.
DISABLED_RULES = [
    "WHITESPACE_RULE",
    "CONSECUTIVE_SPACES",
    "COMMA_PARENTHESIS_WHITESPACE",
    "UPPERCASE_SENTENCE_START",
    "PUNCTUATION_PARAGRAPH_END",
    "EN_QUOTES",
    "DASH_RULE",
    "ARROWS",
    "EN_UNPAIRED_BRACKETS",
    "EN_UNPAIRED_QUOTES",
    # Style preferences rather than errors
    "SENT_START_CONJUNCTIVE_LINKING_ADVERB_COMMA",
    "COMMA_COMPOUND_SENTENCE",
    "COMMA_COMPOUND_SENTENCE_2",
    # False positives on file names (Pipfile.lock), symmetry groups (p2gg) and dataset names
    "LC_AFTER_PERIOD",
    "NUMBERS_IN_WORDS",
    "POSSESSIVE_APOSTROPHE",
]
SPELLING_RULE = re.compile(r"^MORFOLOGIK_RULE_")

MASKS = [
    re.compile(r"\A\+\+\+.*?^\+\+\+$", re.S | re.M),  # TOML front matter
    re.compile(r"^(```|~~~).*?^\1\s*$", re.S | re.M),  # fenced code
    re.compile(r"^(?: {4}|\t).*$", re.M),  # indented code
    re.compile(r"`[^`\n]+`"),  # inline code
    re.compile(r"\$\$.*?\$\$|\\\[.*?\\\]|\\\(.*?\\\)", re.S),  # display/inline maths
    re.compile(r"(?<![\\\w])\$[^$\n]+\$"),  # $inline maths$
    re.compile(r"\{\{.*?\}\}|\{%.*?%\}|\{#.*?#\}", re.S),  # Tera
    re.compile(r"<!--.*?-->", re.S),  # HTML comments
    re.compile(r"</?[A-Za-z][^>]*>"),  # HTML tags
    re.compile(r"^\s*\[[^\]]+\]:\s*\S.*$", re.M),  # reference link definitions
    re.compile(r"\]\([^)]*\)"),  # inline link targets
    re.compile(r"\]\[[^\]]*\]"),  # reference link labels
    re.compile(r"\{#[\w.-]+\}"),  # heading ids
    re.compile(r"https?://\S+"),  # bare URLs
    re.compile(r"\[\^[^\]]+\]"),  # footnote references
    re.compile(r"&#?\w+;"),  # HTML entities
]

# Ignore matches within this many characters of a blanked-out span, where
# LanguageTool sees e.g. "a  ," for "a `ValueError`," and misreports it.
MASK_MARGIN = 2


def blank(text):
    """Replace masked spans with spaces, keeping newlines so offsets line up.

    Returns the blanked text and a per-character flag of what was masked.
    """
    chars = list(text)
    masked = [False] * len(text)
    for pattern in MASKS:
        for m in pattern.finditer(text):
            for i in range(m.start(), m.end()):
                if chars[i] != "\n":
                    chars[i] = " "
                    masked[i] = True
    return "".join(chars), masked


def load_words():
    try:
        with open(WORDS_FILE, encoding="utf-8") as f:
            return {
                line.strip().lower()
                for line in f
                if line.strip() and not line.startswith("#")
            }
    except FileNotFoundError:
        return set()


def check(text):
    data = urllib.parse.urlencode(
        {
            "language": LANGUAGE,
            "text": text,
            "disabledRules": ",".join(DISABLED_RULES),
        }
    ).encode()
    with urllib.request.urlopen(f"{SERVER}/v2/check", data, timeout=120) as resp:
        return json.load(resp)["matches"]


def position(text, offset):
    """1-based line and UTF-8 byte column of a character offset."""
    line_start = text.rfind("\n", 0, offset) + 1
    line = text.count("\n", 0, offset) + 1
    column = len(text[line_start:offset].encode("utf-8")) + 1
    return {"line": line, "column": column}


def main(paths):
    words = load_words()
    for path in paths:
        with open(path, encoding="utf-8") as f:
            text = f.read()
        blanked, masked = blank(text)
        for m in check(blanked):
            start, end = m["offset"], m["offset"] + m["length"]
            if any(masked[max(start - MASK_MARGIN, 0) : end + MASK_MARGIN]):
                continue
            word = text[start:end]
            if SPELLING_RULE.match(m["rule"]["id"]) and word.lower() in words:
                continue
            rng = {"start": position(text, start), "end": position(text, end)}
            diagnostic = {
                "message": m["message"],
                "location": {"path": path, "range": rng},
                "severity": "WARNING",
                "source": {"name": "LanguageTool"},
                "code": {"value": m["rule"]["id"]},
            }
            replacements = [r["value"] for r in m["replacements"][:1]]
            if replacements:
                diagnostic["suggestions"] = [{"range": rng, "text": replacements[0]}]
            print(json.dumps(diagnostic))


if __name__ == "__main__":
    main(sys.argv[1:])
