#!/usr/bin/env python3
"""Local numeric measurement interchange for SeamlyME SMIS and legacy VIT.

Copyright (c) 2026 Sewlore. SPDX-License-Identifier: MIT
No network access, formulas, personal-data inference or external dependencies.
"""
from __future__ import annotations

import argparse
import copy
import csv
import io
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET
from decimal import Decimal, InvalidOperation, localcontext
from datetime import date

VERSION = "0.1.0"
MAX_BYTES = 4 * 1024 * 1024
MAX_ROWS = 10000
FORMATS = {"smis": ("smis", "0.3.4"), "vit": ("vit", "0.3.3")}
FACTORS = {"mm": Decimal("1"), "cm": Decimal("10"), "in": Decimal("25.4")}
HEADERS = ("name", "value", "unit", "full_name", "description")
NUMERIC = re.compile(r"[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?\Z", re.ASCII)
NAME = re.compile(r"[A-Za-z_][A-Za-z_0-9]*\Z", re.ASCII)


class MeasurementError(ValueError):
    """Input is invalid or outside the explicitly supported interchange scope."""


def canonical_unit(unit: str) -> str:
    aliases = {"inch": "in", "inches": "in"}
    result = aliases.get(unit.strip().lower(), unit.strip().lower())
    if result not in FACTORS:
        raise MeasurementError(f"Unsupported unit {unit!r}; use mm, cm or in.")
    return result


def number(value: str, context: str) -> Decimal:
    value = value.strip()
    if len(value) > 100 or not NUMERIC.fullmatch(value):
        raise MeasurementError(f"{context}: {value!r} is not a numeric literal. Formulas are not evaluated.")
    try:
        result = Decimal(value)
    except InvalidOperation as exc:
        raise MeasurementError(f"{context}: invalid number.") from exc
    if not result.is_finite() or abs(result) > Decimal("10000000"):
        raise MeasurementError(f"{context}: number must be finite and within ±10,000,000.")
    if result and abs(result) < Decimal("1e-12"):
        raise MeasurementError(f"{context}: magnitude must be zero or at least 1e-12.")
    return result


def convert(value: Decimal, source: str, target: str) -> Decimal:
    with localcontext() as ctx:
        ctx.prec = 40
        return value * FACTORS[canonical_unit(source)] / FACTORS[canonical_unit(target)]


def decimal_text(value: Decimal) -> str:
    # 15 significant digits avoids artificial precision from repeating inch fractions.
    with localcontext() as ctx:
        ctx.prec = 15
        result = format(+value, "f")
    return result.rstrip("0").rstrip(".") if "." in result else result


def checked_name(name: str) -> str:
    if not NAME.fullmatch(name) or len(name) > 120:
        raise MeasurementError(f"Unsupported measurement name {name!r}; use an ASCII letter/underscore followed by letters, digits or underscores.")
    return name


def xml_root(path: Path) -> ET.Element:
    raw = path.read_bytes()
    if len(raw) > MAX_BYTES:
        raise MeasurementError("XML is larger than the 4 MiB limit.")
    declaration_scan = raw.replace(b"\x00", b"").upper()
    if b"<!DOCTYPE" in declaration_scan or b"<!ENTITY" in declaration_scan:
        raise MeasurementError("DOCTYPE and ENTITY declarations are not accepted.")
    try:
        root = ET.fromstring(raw)
    except ET.ParseError as exc:
        raise MeasurementError(f"Invalid XML: {exc}.") from exc
    expected = FORMATS.get(root.tag)
    if not expected or root.findtext("version") != expected[1]:
        raise MeasurementError("Supported formats are <vit> version 0.3.3 and <smis> version 0.3.4 only.")
    canonical_unit(root.findtext("unit", ""))
    required = ["version", "read-only", "notes", "unit", "pm_system", "personal", "body-measurements"]
    actual = [child.tag for child in root]
    if actual not in (required, [tag for tag in required if tag != "notes"]):
        raise MeasurementError("XML requires the Seamly schema element order; unknown or repeated sections are not accepted.")
    if root.findtext("read-only") not in ("true", "false", "1", "0"):
        raise MeasurementError("read-only must be true, false, 1 or 0.")
    pm_system = root.findtext("pm_system", "")
    if not re.fullmatch(r"(?:[0-9]|[1-4][0-9]|5[0-4]|998)", pm_system):
        raise MeasurementError("Invalid pm_system code.")
    personal = root.find("personal")
    if [child.tag for child in personal] != ["family-name", "given-name", "birth-date", "gender", "email"]:
        raise MeasurementError("Invalid personal metadata section.")
    try:
        birth_date = personal.findtext("birth-date", "")
        if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", birth_date):
            raise ValueError("Expected YYYY-MM-DD")
        date.fromisoformat(birth_date)
    except ValueError as exc:
        raise MeasurementError("birth-date must be a valid ISO date.") from exc
    if personal.findtext("gender") not in ("unknown", "male", "female"):
        raise MeasurementError("Invalid gender value.")
    return root


def read_xml(path: Path, target_unit: str | None = None) -> tuple[list[dict[str, str]], ET.Element]:
    root = xml_root(path)
    source_unit = canonical_unit(root.findtext("unit", ""))
    target = canonical_unit(target_unit or source_unit)
    children = list(root.find("body-measurements"))
    if len(children) > MAX_ROWS:
        raise MeasurementError("Too many measurements; limit is 10,000.")
    rows, names = [], set()
    for child in children:
        if child.tag != "m":
            raise MeasurementError(f"Unexpected measurement element {child.tag!r}.")
        if set(child.attrib) - {"name", "value", "full_name", "description"}:
            raise MeasurementError("Unknown measurement attributes are not accepted.")
        name = checked_name(child.get("name", ""))
        if name in names:
            raise MeasurementError(f"Duplicate measurement name {name!r}.")
        names.add(name)
        value = number(child.get("value", ""), name)
        row = {"name": name, "value": decimal_text(convert(value, source_unit, target)), "unit": target,
               "full_name": child.get("full_name", ""), "description": child.get("description", "")}
        rows.append(row)
    if not rows:
        raise MeasurementError("No measurements found.")
    return rows, root


def safe_csv_text(value: str, context: str) -> str:
    # Reject instead of silently changing a description or generating active spreadsheet cells.
    if value.lstrip(" \r\n").startswith(("=", "+", "-", "@", "\t")):
        raise MeasurementError(f"{context}: spreadsheet-active label is not exported. Remove the leading formula character in a copy of the source.")
    return value


def csv_bytes(rows: list[dict[str, str]]) -> bytes:
    stream = io.StringIO(newline="")
    writer = csv.DictWriter(stream, fieldnames=HEADERS, lineterminator="\n")
    writer.writeheader()
    for row in rows:
        for column in ("full_name", "description"):
            safe_csv_text(row[column], f"{row['name']} {column}")
        writer.writerow(row)
    return stream.getvalue().encode("utf-8")


def read_csv(path: Path, target_unit: str) -> list[dict[str, str]]:
    raw = path.read_bytes()
    if len(raw) > MAX_BYTES:
        raise MeasurementError("CSV is larger than the 4 MiB limit.")
    try:
        reader = csv.DictReader(io.StringIO(raw.decode("utf-8-sig"), newline=""), strict=True)
        if not reader.fieldnames or len(set(reader.fieldnames)) != len(reader.fieldnames):
            raise MeasurementError("CSV requires unique column names.")
        if not {"name", "value", "unit"}.issubset(reader.fieldnames) or set(reader.fieldnames) - set(HEADERS):
            raise MeasurementError("CSV requires name,value,unit and permits only full_name,description as extra columns.")
        rows, names = [], set()
        target = canonical_unit(target_unit)
        for line, original in enumerate(reader, start=2):
            if len(rows) >= MAX_ROWS:
                raise MeasurementError("Too many measurements; limit is 10,000.")
            if None in original or any(v is None for v in original.values()):
                raise MeasurementError(f"CSV row {line}: wrong number of cells.")
            name = checked_name(original["name"].strip())
            if name in names:
                raise MeasurementError(f"Duplicate measurement name {name!r} at row {line}.")
            names.add(name)
            value = number(original["value"], f"CSV row {line} {name}")
            unit = canonical_unit(original["unit"])
            rows.append({"name": name, "value": decimal_text(convert(value, unit, target)), "unit": target,
                         "full_name": original.get("full_name", ""), "description": original.get("description", "")})
    except (UnicodeError, csv.Error) as exc:
        raise MeasurementError(f"Invalid UTF-8 CSV: {exc}.") from exc
    if not rows:
        raise MeasurementError("No CSV measurement rows found.")
    return rows


def new_root(format_name: str, unit: str) -> ET.Element:
    root = ET.Element(FORMATS[format_name][0])
    for name, value in (("version", FORMATS[format_name][1]), ("read-only", "false"),
                        ("notes", "Created by Sewlore Measurement Interchange. Verify measurement names and values before drafting."),
                        ("unit", "inch" if unit == "in" else unit), ("pm_system", "998")):
        ET.SubElement(root, name).text = value
    personal = ET.SubElement(root, "personal")
    for name, value in (("family-name", ""), ("given-name", ""), ("birth-date", "1800-01-01"),
                        ("gender", "unknown"), ("email", "")):
        ET.SubElement(personal, name).text = value
    ET.SubElement(root, "body-measurements")
    return root


def xml_bytes(rows: list[dict[str, str]], format_name: str, target_unit: str, template: Path | None = None) -> bytes:
    target = canonical_unit(target_unit)
    root = copy.deepcopy(xml_root(template)) if template else new_root(format_name, target)
    root.tag = FORMATS[format_name][0]
    root.find("version").text = FORMATS[format_name][1]
    root.find("unit").text = "inch" if target == "in" else target
    if template and root.findtext("read-only") in ("true", "1"):
        raise MeasurementError("Template is marked read-only; make an editable copy in SeamlyME first.")
    body = root.find("body-measurements")
    body.clear()
    for row in rows:
        attributes = {"name": row["name"], "value": row["value"]}
        for key, column in (("full_name", "full_name"), ("description", "description")):
            if row.get(column):
                attributes[key] = row[column]
        ET.SubElement(body, "m", attributes)
    ET.indent(root, "  ")
    return ET.tostring(root, encoding="utf-8", xml_declaration=True) + b"\n"


def write_new(path: Path, data: bytes, inputs: list[Path]) -> None:
    if path.resolve() in [p.resolve() for p in inputs]:
        raise MeasurementError("Output must differ from every input; originals are never overwritten.")
    if path.exists():
        raise MeasurementError(f"Output {path} already exists. Choose a new filename.")
    path.parent.mkdir(parents=True, exist_ok=True)
    # Exclusive creation prevents an accidental overwrite even if a second process races us.
    with path.open("xb") as stream:
        stream.write(data)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--version", action="version", version=VERSION)
    sub = parser.add_subparsers(dest="command", required=True)
    export = sub.add_parser("to-csv", help="Export numeric VIT/SMIS values to unit-normalized CSV.")
    export.add_argument("input", type=Path)
    export.add_argument("output", type=Path)
    export.add_argument("--unit", choices=tuple(FACTORS))
    create = sub.add_parser("from-csv", help="Create SMIS or legacy VIT from per-row units.")
    create.add_argument("input", type=Path)
    create.add_argument("output", type=Path)
    create.add_argument("--unit", choices=tuple(FACTORS), default="cm")
    create.add_argument("--format", choices=tuple(FORMATS), default="smis")
    create.add_argument("--template", type=Path, help="Preserve notes and personal metadata from your original editable file.")
    args = parser.parse_args(argv)
    try:
        if args.command == "to-csv":
            rows, _ = read_xml(args.input, args.unit)
            data, inputs = csv_bytes(rows), [args.input]
        else:
            rows = read_csv(args.input, args.unit)
            expected_suffix = "." + args.format
            if args.output.suffix.lower() != expected_suffix:
                raise MeasurementError(f"Output extension must be {expected_suffix} for --format {args.format}.")
            data = xml_bytes(rows, args.format, args.unit, args.template)
            inputs = [args.input] + ([args.template] if args.template else [])
        write_new(args.output, data, inputs)
        print(f"Wrote {len(rows)} measurements to {args.output}.")
        return 0
    except (MeasurementError, OSError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
