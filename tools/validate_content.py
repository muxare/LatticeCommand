#!/usr/bin/env python3
"""Validate the game content in content/ against its JSON Schemas and the
cross-file rules a schema cannot express.

Decisions behind it: ADR-0009 (content is JSON validated by JSON Schema),
ADR-0010 (every technical claim lives in content/facts.json), ADR-0020
(integer numerics) and ADR-0023 (a standard JSON Schema validator outside
Godot plus a project script, and the glossary of fact `terms`).

Layout it expects:
    content/facts.json            -> tools/schemas/facts.schema.json
    content/incidents/<id>.json   -> tools/schemas/incident.schema.json
Hidden files such as .gitkeep are ignored. Any other file under content/
is an error, so a new kind of content has to arrive with its schema.

Usage:
    .venv/bin/python tools/validate_content.py [--content-dir DIR]

Every error is printed on its own line as `file: path: message`, where
`path` is a JSON Pointer into the document (`/` is the whole document).
The exit status is 0 when the content is valid, 1 when any error was found
and 2 for a usage error.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any, Dict, Iterator, List, Optional, Set, Tuple

try:
    from jsonschema import Draft202012Validator, FormatChecker
except ImportError:  # pragma: no cover - exercised only without the venv
    sys.stdout.write(
        "tools/validate_content.py: /: the jsonschema package is missing; "
        "install it with: python3 -m venv .venv && "
        ".venv/bin/python -m pip install -r tools/requirements.txt\n"
    )
    sys.exit(1)

TOOLS_DIR = Path(__file__).resolve().parent
REPO_ROOT = TOOLS_DIR.parent
SCHEMA_DIR = TOOLS_DIR / "schemas"
DEFAULT_CONTENT_DIR = REPO_ROOT / "content"
DEFAULT_AGENTS_DIR = REPO_ROOT / ".claude" / "agents"

FACTS_FILE = "facts.json"
INCIDENTS_DIR = "incidents"

# ADR-0020: rule values stay within +/-2^40.
MAX_ABS_INT = 2 ** 40

# Incident keys whose string values are identifiers or enum values rather
# than prose, so the glossary check does not scan them.
IDENTIFIER_KEYS = {
    "id",
    "colony_type",
    "domain",
    "task_statement",
    "solution",
    "order",
    "doctrine",
    "fact_ids",
}

# Words that mark a verifier as an agent rather than a person (ADR-0023).
# The names of the project's subagents are added from .claude/agents/.
AGENT_WORDS = {"claude", "subagent", "agent", "ai", "bot", "assistant", "llm"}

# A sentence end followed by whitespace inside a claim means a second
# sentence. Abbreviations such as "e.g." also trip it; rephrase them.
SECOND_SENTENCE = re.compile(r"[.!?][\"')\]]*\s")


class DuplicateKeyError(ValueError):
    pass


class Report:
    def __init__(self) -> None:
        self.errors: List[Tuple[str, str, str]] = []

    def add(self, file: str, path: str, message: str) -> None:
        self.errors.append((file, path or "/", message))

    def lines(self) -> List[str]:
        return ["%s: %s: %s" % error for error in self.errors]


def pointer(parts: Any) -> str:
    """Return the JSON Pointer for a sequence of keys and indices."""
    parts = list(parts)
    if not parts:
        return "/"
    escaped = (str(p).replace("~", "~0").replace("/", "~1") for p in parts)
    return "/" + "/".join(escaped)


def _reject_duplicates(pairs: List[Tuple[str, Any]]) -> Dict[str, Any]:
    result: Dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise DuplicateKeyError("duplicate key %r" % key)
        result[key] = value
    return result


def _reject_constant(name: str) -> Any:
    raise ValueError("%s is not valid JSON" % name)


def load_json(path: Path, display: str, report: Report) -> Tuple[bool, Any]:
    try:
        text = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        report.add(display, "/", "cannot read file as UTF-8: %s" % exc)
        return False, None
    try:
        data = json.loads(
            text,
            object_pairs_hook=_reject_duplicates,
            parse_constant=_reject_constant,
        )
    except json.JSONDecodeError as exc:
        report.add(display, "/", "invalid JSON: %s (line %d, column %d)"
                   % (exc.msg, exc.lineno, exc.colno))
        return False, None
    except ValueError as exc:
        report.add(display, "/", "invalid JSON: %s" % exc)
        return False, None
    return True, data


def load_schema(name: str) -> Draft202012Validator:
    schema = json.loads((SCHEMA_DIR / name).read_text(encoding="utf-8"))
    Draft202012Validator.check_schema(schema)
    return Draft202012Validator(schema, format_checker=FormatChecker())


def walk(value: Any, path: Tuple[Any, ...] = ()) -> Iterator[Tuple[Tuple[Any, ...], Any]]:
    """Yield (path, value) for every value in a JSON document."""
    yield path, value
    if isinstance(value, dict):
        for key, child in value.items():
            yield from walk(child, path + (key,))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from walk(child, path + (index,))


def schema_message(error: Any) -> str:
    """Shorten jsonschema messages that would print a whole array or regex."""
    if error.validator == "minItems":
        return "has %d item(s); at least %d are required" % (
            len(error.instance), error.validator_value)
    if error.validator == "maxItems":
        return "has %d item(s); at most %d are allowed" % (
            len(error.instance), error.validator_value)
    if error.validator == "pattern" and "description" in error.schema:
        return "%r is not valid: %s" % (error.instance, error.schema["description"])
    return error.message


def check_schema(validator: Draft202012Validator, data: Any, display: str,
                 report: Report) -> bool:
    errors = sorted(validator.iter_errors(data),
                    key=lambda e: (pointer(e.absolute_path), e.message))
    for error in errors:
        report.add(display, pointer(error.absolute_path), schema_message(error))
    return not errors


def check_generic(data: Any, display: str, report: Report) -> None:
    """Rules for every content file: integer numerics and trimmed strings."""
    for path, value in walk(data):
        if isinstance(value, bool):
            continue
        if isinstance(value, float):
            report.add(display, pointer(path),
                       "number %r must be written as an integer; content holds "
                       "no fractional or exponent numbers (ADR-0020)" % value)
        elif isinstance(value, int) and abs(value) > MAX_ABS_INT:
            report.add(display, pointer(path),
                       "integer %d is outside +/-2^40 (ADR-0020)" % value)
        elif isinstance(value, str) and value != value.strip():
            report.add(display, pointer(path),
                       "string has leading or trailing whitespace")


def agent_names(agents_dir: Path) -> Set[str]:
    names: Set[str] = set()
    if not agents_dir.is_dir():
        return names
    for path in sorted(agents_dir.glob("*.md")):
        names.add(path.stem.lower())
        for line in path.read_text(encoding="utf-8").splitlines()[1:]:
            if line.strip() == "---":
                break
            if line.startswith("name:"):
                names.add(line[len("name:"):].strip().strip("\"'").lower())
    return names


def check_facts(facts: List[Dict[str, Any]], display: str, agents: Set[str],
                report: Report) -> None:
    seen: Dict[str, int] = {}
    for index, fact in enumerate(facts):
        fact_id = fact["id"]
        if fact_id in seen:
            report.add(display, pointer((index, "id")),
                       "duplicate fact id %r, first used at %s"
                       % (fact_id, pointer((seen[fact_id], "id"))))
        else:
            seen[fact_id] = index

        claim = fact["claim"]
        if SECOND_SENTENCE.search(claim[:-1]):
            report.add(display, pointer((index, "claim")),
                       "claim must be one sentence")

        verifier = fact["verifier"]
        lowered = verifier.lower()
        words = set(re.split(r"[^a-z0-9-]+", lowered)) | set(re.split(r"[^a-z0-9]+", lowered))
        if lowered in agents or words & (AGENT_WORDS | agents):
            report.add(display, pointer((index, "verifier")),
                       "verifier %r names an agent; it must be the person who "
                       "approved the entry (ADR-0023)" % verifier)


def term_pattern(term: str) -> "re.Pattern[str]":
    return re.compile(r"(?<![A-Za-z0-9_])" + re.escape(term) + r"(?![A-Za-z0-9_])",
                      re.IGNORECASE)


def text_values(value: Any, path: Tuple[Any, ...] = ()) -> Iterator[Tuple[Tuple[Any, ...], str]]:
    """Yield the prose strings of an incident, skipping identifier fields."""
    if isinstance(value, dict):
        for key, child in value.items():
            if key not in IDENTIFIER_KEYS:
                yield from text_values(child, path + (key,))
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from text_values(child, path + (index,))
    elif isinstance(value, str):
        yield path, value


def check_incident(incident: Dict[str, Any], file_stem: str, display: str,
                   fact_ids: Optional[Set[str]],
                   glossary: Dict[str, Set[str]], report: Report) -> None:
    if incident["id"] != file_stem:
        report.add(display, "/id",
                   "id %r must equal the file name %r" % (incident["id"], file_stem))

    if incident["task_statement"].split(".")[0] != incident["domain"][1:]:
        report.add(display, "/task_statement",
                   "task statement %r does not belong to domain %s"
                   % (incident["task_statement"], incident["domain"]))

    orders: Dict[str, int] = {}
    for index, order in enumerate(incident["orders"]):
        if order["id"] in orders:
            report.add(display, pointer(("orders", index, "id")),
                       "duplicate order id %r" % order["id"])
        else:
            orders[order["id"]] = index

    solution = set(incident["solution"])
    for index, order_id in enumerate(incident["solution"]):
        if order_id not in orders:
            report.add(display, pointer(("solution", index)),
                       "unknown order id %r" % order_id)

    wrong: Set[str] = set()
    for index, entry in enumerate(incident["wrong_orders"]):
        order_id = entry["order"]
        path = pointer(("wrong_orders", index, "order"))
        if order_id not in orders:
            report.add(display, path, "unknown order id %r" % order_id)
        elif order_id in solution:
            report.add(display, path,
                       "order %r is both in the solution and a wrong order" % order_id)
        elif order_id in wrong:
            report.add(display, path, "order %r is listed as wrong twice" % order_id)
        wrong.add(order_id)

    for order_id, index in orders.items():
        if order_id not in solution and order_id not in wrong:
            report.add(display, pointer(("orders", index, "id")),
                       "order %r is neither in the solution nor a wrong order"
                       % order_id)

    listed = set(incident["fact_ids"])
    if fact_ids is not None:
        for index, fact_id in enumerate(incident["fact_ids"]):
            if fact_id not in fact_ids:
                report.add(display, pointer(("fact_ids", index)),
                           "fact id %r does not exist in content/%s"
                           % (fact_id, FACTS_FILE))

    for path, text in text_values(incident):
        for term in sorted(glossary):
            if term_pattern(term).search(text) and not (glossary[term] & listed):
                report.add(display, pointer(path),
                           "names the feature %r, but fact_ids lists none of the "
                           "facts that back it: %s"
                           % (term, ", ".join(sorted(glossary[term]))))


def display_name(path: Path, content_dir: Path) -> str:
    return (Path(content_dir.name) / path.relative_to(content_dir)).as_posix()


def is_hidden(path: Path, content_dir: Path) -> bool:
    return any(part.startswith(".") for part in path.relative_to(content_dir).parts)


def validate(content_dir: Path, agents_dir: Path = DEFAULT_AGENTS_DIR) -> Report:
    report = Report()
    facts_validator = load_schema("facts.schema.json")
    incident_validator = load_schema("incident.schema.json")
    agents = agent_names(agents_dir)

    facts_path = content_dir / FACTS_FILE
    incident_paths: List[Path] = []
    for path in sorted(content_dir.rglob("*")):
        if path.is_dir() or is_hidden(path, content_dir):
            continue
        relative = path.relative_to(content_dir)
        if path == facts_path:
            continue
        if (len(relative.parts) == 2 and relative.parts[0] == INCIDENTS_DIR
                and path.suffix == ".json"):
            incident_paths.append(path)
            continue
        report.add(display_name(path, content_dir), "/",
                   "no schema covers this file; add one in tools/schemas/ and "
                   "tools/validate_content.py before adding a new kind of content")

    # The fact sheet. Without it, no fact id resolves and the glossary is empty.
    fact_ids: Optional[Set[str]] = set()
    glossary: Dict[str, Set[str]] = {}
    if facts_path.is_file():
        display = display_name(facts_path, content_dir)
        ok, facts = load_json(facts_path, display, report)
        if ok:
            check_generic(facts, display, report)
            if check_schema(facts_validator, facts, display, report):
                check_facts(facts, display, agents, report)
                for fact in facts:
                    fact_ids.add(fact["id"])
                    for term in fact["terms"]:
                        glossary.setdefault(term, set()).add(fact["id"])
            else:
                fact_ids = None
        else:
            fact_ids = None
    # fact_ids is None when the fact sheet is broken; its own errors are
    # reported above and fact references are not checked against it.

    for path in incident_paths:
        display = display_name(path, content_dir)
        ok, incident = load_json(path, display, report)
        if not ok:
            continue
        check_generic(incident, display, report)
        if check_schema(incident_validator, incident, display, report):
            check_incident(incident, path.stem, display, fact_ids, glossary, report)

    return report


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--content-dir", type=Path, default=DEFAULT_CONTENT_DIR,
                        help="content directory to validate (default: content/)")
    parser.add_argument("--agents-dir", type=Path, default=DEFAULT_AGENTS_DIR,
                        help="subagent definitions whose names may not be a "
                             "verifier (default: .claude/agents/)")
    args = parser.parse_args(argv)

    content_dir = args.content_dir.resolve()
    if not content_dir.is_dir():
        print("%s: /: content directory does not exist" % args.content_dir)
        return 1

    report = validate(content_dir, args.agents_dir.resolve())
    for line in report.lines():
        print(line)
    if report.errors:
        print("content validation failed: %d error(s)" % len(report.errors))
        return 1
    print("content validation passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
