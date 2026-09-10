"""Minimal YAML dump/load for the lab's simple mappings.

Stdlib only. Supports the subset used by state.yaml, experiment.yaml and
profiles.yaml: nested dicts, lists, strings, ints, floats, bools, null.
"""

from __future__ import annotations

from typing import Any


def dump(data: Any) -> str:
    lines: list[str] = []
    _dump(data, lines, indent=0)
    return "\n".join(lines).rstrip() + "\n"


def _dump(data: Any, lines: list[str], indent: int) -> None:
    pad = "  " * indent
    if isinstance(data, dict):
        if not data:
            lines.append(f"{pad}{{}}")
            return
        for key, value in data.items():
            key_s = str(key)
            if isinstance(value, (dict, list)):
                if not value:
                    empty = "{}" if isinstance(value, dict) else "[]"
                    lines.append(f"{pad}{key_s}: {empty}")
                else:
                    lines.append(f"{pad}{key_s}:")
                    _dump(value, lines, indent + 1)
            else:
                lines.append(f"{pad}{key_s}: {_scalar(value)}")
    elif isinstance(data, list):
        if not data:
            lines.append(f"{pad}[]")
            return
        for item in data:
            if isinstance(item, (dict, list)):
                lines.append(f"{pad}-")
                _dump(item, lines, indent + 1)
            else:
                lines.append(f"{pad}- {_scalar(item)}")
    else:
        lines.append(f"{pad}{_scalar(data)}")


def _scalar(value: Any) -> str:
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    text = str(value)
    if text == "":
        return '""'
    special = any(ch in text for ch in ":#{}[]&*!|>%@`'\"\n")
    if text.lower() in {"true", "false", "null", "yes", "no"} or special or text[:1].isspace():
        return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'
    return text


def load(text: str) -> Any:
    """Tiny indented-block loader for lab YAML (dicts/lists/scalars)."""
    lines = []
    for raw in text.splitlines():
        if (not raw.strip()) or raw.lstrip().startswith("#"):
            continue
        indent = len(raw) - len(raw.lstrip(" "))
        lines.append((indent, raw.strip()))
    if not lines:
        return {}
    value, _ = _parse_block(lines, 0, lines[0][0])
    return value


def _parse_block(lines: list[tuple[int, str]], idx: int, indent: int) -> tuple[Any, int]:
    if idx >= len(lines):
        return {}, idx
    _, content = lines[idx]
    if content.startswith("- ") or content == "-":
        return _parse_list(lines, idx, indent)
    return _parse_dict(lines, idx, indent)


def _parse_dict(lines: list[tuple[int, str]], idx: int, indent: int) -> tuple[dict[str, Any], int]:
    result: dict[str, Any] = {}
    while idx < len(lines):
        i, content = lines[idx]
        if i < indent:
            break
        if i > indent:
            raise ValueError(f"Unexpected indent at: {content}")
        if content.startswith("- ") or content == "-":
            break
        if ":" not in content:
            raise ValueError(f"Expected key: value, got {content!r}")
        key, rest = content.split(":", 1)
        key = key.strip()
        rest = rest.strip()
        idx += 1
        if rest == "":
            if idx < len(lines) and lines[idx][0] > indent:
                value, idx = _parse_block(lines, idx, lines[idx][0])
            else:
                value = None
        else:
            value = _parse_scalar(rest)
        result[key] = value
    return result, idx


def _parse_list(lines: list[tuple[int, str]], idx: int, indent: int) -> tuple[list[Any], int]:
    result: list[Any] = []
    while idx < len(lines):
        i, content = lines[idx]
        if i < indent:
            break
        if not (content.startswith("- ") or content == "-"):
            break
        rest = content[1:].strip()
        idx += 1
        if rest == "":
            if idx < len(lines) and lines[idx][0] > indent:
                value, idx = _parse_block(lines, idx, lines[idx][0])
            else:
                value = None
        elif rest.endswith(":") and idx < len(lines) and lines[idx][0] > indent:
            key = rest[:-1].strip()
            nested, idx = _parse_block(lines, idx, lines[idx][0])
            value = {key: nested}
        elif ":" in rest and not rest.startswith("{") and not rest.startswith("["):
            # inline map on a list item: "key: value"
            k, v = rest.split(":", 1)
            extra: dict[str, Any] = {k.strip(): _parse_scalar(v.strip())}
            while idx < len(lines) and lines[idx][0] > indent and not (
                lines[idx][1].startswith("- ") or lines[idx][1] == "-"
            ):
                ni, ncontent = lines[idx]
                if ":" not in ncontent:
                    break
                nk, nv = ncontent.split(":", 1)
                extra[nk.strip()] = _parse_scalar(nv.strip()) if nv.strip() else None
                idx += 1
            value = extra
        else:
            value = _parse_scalar(rest)
        result.append(value)
    return result, idx


def _parse_scalar(text: str) -> Any:
    if text in {"null", "~", ""}:
        return None
    if text.lower() == "true":
        return True
    if text.lower() == "false":
        return False
    if (text.startswith('"') and text.endswith('"')) or (
        text.startswith("'") and text.endswith("'")
    ):
        return text[1:-1]
    try:
        if "." in text:
            return float(text)
        return int(text)
    except ValueError:
        return text
