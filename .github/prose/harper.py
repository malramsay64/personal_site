"""Check Markdown files with harper-cli and print reviewdog rdjsonl.

Usage: python3 harper.py FILE... | reviewdog -f=rdjsonl ...
       python3 harper.py --text FILE...   (readable output, for local use)

Harper parses Markdown itself (skipping code and links), but not LaTeX maths or
Tera, so lints inside those are dropped here.
"""

import json
import os
import re
import subprocess
import sys

HARPER = os.environ.get("HARPER", "harper-cli")
DIALECT = os.environ.get("HARPER_DIALECT", "au")
DICTIONARY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "dictionary.txt")

# Style preferences rather than errors, and rules that misfire on technical
# writing with semantic line breaks.
IGNORED_RULES = [
    "SentenceCapitalization",  # sentences continued after a code block
    "LongSentences",
    "UseTitleCase",
    "OxfordComma",
    "Dashes",
    "UseEllipsisCharacter",
    "DiscourseMarkers",
    "DisjointPrefixes",  # pre-installed vs preinstalled
    "SplitWords",  # setuptools -> setup tools
    "MassNouns",
    "ExpandMemoryShorthands",
    "ExpandStandardInputAndOutput",
    "ExpandConfiguration",
    "ExpandMinimum",
    "OrthographicConsistency",  # numpy -> NumPy, mostly identifiers outside backticks
    "CompoundNouns",  # flip side -> flipside
]

# Spans Harper doesn't understand: TOML front matter, LaTeX maths and Tera.
SKIP = re.compile(
    r"\A\+\+\+.*?^\+\+\+$"
    r"|\$\$.*?\$\$|\\\[.*?\\\]|\\\(.*?\\\)|(?<![\\\w])\$[^$\n]+\$"
    r"|\{\{.*?\}\}|\{%.*?%\}",
    re.S | re.M,
)

REPLACE = re.compile(r"^Replace with: “(.*)”$", re.S)
INSERT = re.compile(r"^Insert “(.*)”$", re.S)


def position(text, offset):
    """1-based line and UTF-8 byte column of a character offset."""
    line_start = text.rfind("\n", 0, offset) + 1
    return {
        "line": text.count("\n", 0, offset) + 1,
        "column": len(text[line_start:offset].encode("utf-8")) + 1,
    }


def suggestion(text, start, end, raw):
    """Convert a Harper suggestion string into an rdjson suggestion."""
    if m := REPLACE.match(raw):
        return {"start": start, "end": end, "text": m.group(1)}
    if m := INSERT.match(raw):
        return {"start": end, "end": end, "text": m.group(1)}
    if raw == "Remove error":
        return {"start": start, "end": end, "text": ""}
    return None


def load_dictionary():
    # Applied here rather than with --user-dict-path, because harper-cli 2.13
    # only honours user dictionary words for the American dialect.
    with open(DICTIONARY, encoding="utf-8") as f:
        return {line.strip().lower() for line in f if line.strip()}


def lint(path):
    # harper-cli exits non-zero when it finds lints, so don't check the status.
    result = subprocess.run(
        [
            HARPER, "lint", path,
            "--format", "json", "--quiet",
            "--dialect", DIALECT,
            "--ignore", ",".join(IGNORED_RULES),
        ],
        capture_output=True, text=True,
    )
    try:
        return json.loads(result.stdout)
    except json.JSONDecodeError:
        sys.exit(f"harper-cli failed on {path}:\n{result.stderr}")


def as_text(d):
    start = d["location"]["range"]["start"]
    fix = f" (suggest: {d['suggestions'][0]['text']!r})" if "suggestions" in d else ""
    return f"{d['location']['path']}:{start['line']}:{start['column']}: {d['code']['value']}: {d['message']}{fix}"


def main(paths, text_output=False):
    words = load_dictionary()
    for path in paths:
        with open(path, encoding="utf-8") as f:
            text = f.read()
        skipped = [(m.start(), m.end()) for m in SKIP.finditer(text)]
        for result in lint(path):
            for item in result["lints"]:
                start, end = item["span"]["char_start"], item["span"]["char_end"]
                if any(s < end and start < e for s, e in skipped):
                    continue
                if item["rule"] == "SpellCheck" and item["matched_text"].lower() in words:
                    continue
                diagnostic = {
                    "message": item["message"],
                    "location": {
                        "path": path,
                        "range": {"start": position(text, start), "end": position(text, end)},
                    },
                    "severity": "WARNING",
                    "source": {"name": "Harper"},
                    "code": {"value": item["rule"]},
                }
                if item["suggestions"] and (s := suggestion(text, start, end, item["suggestions"][0])):
                    rng = {"start": position(text, s["start"]), "end": position(text, s["end"])}
                    diagnostic["suggestions"] = [{"range": rng, "text": s["text"]}]
                print(as_text(diagnostic) if text_output else json.dumps(diagnostic))


if __name__ == "__main__":
    args = sys.argv[1:]
    text_output = bool(args) and args[0] == "--text"
    main(args[1:] if text_output else args, text_output)
