#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
import re
import shutil
import subprocess
import tempfile
from dataclasses import dataclass
from datetime import date, datetime
from pathlib import Path
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
ARTICLES = DOCS / "articles"
INCOMING = ROOT / "incoming"
INCOMING_TYP = INCOMING / "typst"
MANIFEST = INCOMING / "manifest.csv"
LOCAL_FONT_ROOTS = (ROOT / "fonts",)
FONT_FILE_SUFFIXES = (".ttf", ".otf", ".ttc", ".otc", ".woff", ".woff2")
WEB_FONT_ASSETS = (
    ("merriweather", ("Merriweather-Regular.ttf", "README.md", "LICENSE.txt")),
    ("roboto-condensed", ("RobotoCondensed-Regular.ttf", "README.md", "LICENSE.txt")),
    ("lxgw-wenkai", ("LXGWWenKai-Light.ttf", "LXGWWenKai-Regular.ttf", "LXGWWenKai-Medium.ttf", "README.md", "OFL.txt")),
)
AUTO_DATE_WORDS = {"auto", "today", "current"}
MONTH_NAMES = (
    "January",
    "February",
    "March",
    "April",
    "May",
    "June",
    "July",
    "August",
    "September",
    "October",
    "November",
    "December",
)


def parse_tags(raw: str) -> tuple[str, ...]:
    if not raw:
        return ()

    seen: set[str] = set()
    tags: list[str] = []
    for part in re.split(r"[;；]+", raw):
        tag = " ".join(part.strip().split())
        if not tag:
            continue
        key = tag.casefold()
        if key in seen:
            continue
        seen.add(key)
        tags.append(tag)

    return tuple(tags)


@dataclass(frozen=True)
class Row:
    typ_file: str
    slug: str
    title: str
    date: str
    excerpt: str
    tags: tuple[str, ...] = ()


@dataclass(frozen=True)
class BuildDateContext:
    iso: str
    display: str
    timezone: str


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Publish posts from incoming Typst sources (Typst→PDF) into docs/ and rebuild index.")
    p.add_argument("--manifest", default=str(MANIFEST), help="CSV manifest path (default: incoming/manifest.csv)")
    p.add_argument("--typst-root", default="", help="Pass as --root to typst compile (default: each .typ parent)")
    p.add_argument("--skip-compile", action="store_true", help="Skip Typst compilation (assume docs/articles/<slug>/doc.pdf already exists)")
    p.add_argument("--skip-index", action="store_true", help="Skip regenerating docs/data/posts.json")
    p.add_argument(
        "--typst-date-mode",
        choices=("source", "today", "first-publish"),
        default="source",
        help=(
            "How to set the date shown inside the compiled Typst/PDF. "
            "'source' keeps the source file's own date line; "
            "'today' always injects the build date; "
            "'first-publish' uses today's date only for newly published posts and preserves the old date for existing ones."
        ),
    )
    p.add_argument(
        "--build-timezone",
        default="Asia/Shanghai",
        help="IANA timezone used for build-date injection and date=auto (default: Asia/Shanghai)",
    )
    p.add_argument(
        "--sync-typst-source-date",
        action="store_true",
        help=(
            "When used with --typst-date-mode=first-publish, permanently write the locked first-publish date "
            "back into brand-new Typst source files so the source and published PDF stay in sync."
        ),
    )
    return p.parse_args()


def read_manifest(path: Path) -> list[Row]:
    if not path.exists():
        raise SystemExit(f"Manifest not found: {path}")

    rows: list[Row] = []
    with path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        required = {"typ_file", "slug", "title", "date"}
        missing = required - set(reader.fieldnames or [])
        if missing:
            raise SystemExit(f"Manifest missing column(s): {', '.join(sorted(missing))}")

        for i, rec in enumerate(reader, start=2):
            first = (rec.get("typ_file") or "").strip()
            if first.startswith("#"):
                continue

            if not any((rec.get(k) or "").strip() for k in (reader.fieldnames or [])):
                continue

            typ_file = (rec.get("typ_file") or "").strip()
            slug = (rec.get("slug") or "").strip()
            title = (rec.get("title") or "").strip()
            date_value = (rec.get("date") or "").strip()
            excerpt = (rec.get("excerpt") or "").strip()
            tags = parse_tags((rec.get("tags") or "").strip())

            if not slug:
                raise SystemExit(f"Line {i}: empty slug")
            if not title:
                raise SystemExit(f"Line {i}: empty title for slug={slug}")
            if not date_value:
                raise SystemExit(f"Line {i}: empty date for slug={slug}")
            if not typ_file:
                raise SystemExit(f"Line {i}: typ_file required (Typst-only mode) for slug={slug}")

            rows.append(Row(typ_file=typ_file, slug=slug, title=title, date=date_value, excerpt=excerpt, tags=tags))

    slugs = [r.slug for r in rows]
    if len(slugs) != len(set(slugs)):
        dupes = sorted({s for s in slugs if slugs.count(s) > 1})
        raise SystemExit(f"Duplicate slug(s): {', '.join(dupes)}")
    return rows


def get_build_date_context(timezone_name: str) -> BuildDateContext:
    try:
        tz = ZoneInfo(timezone_name)
    except ZoneInfoNotFoundError as exc:
        raise SystemExit(
            "Invalid build timezone. Please use a valid IANA timezone name, for example 'Asia/Shanghai' or 'UTC'.\n"
            f"Received: {timezone_name}"
        ) from exc

    today = datetime.now(tz).date()
    display = format_display_date(today.isoformat())
    return BuildDateContext(iso=today.isoformat(), display=display, timezone=timezone_name)


def format_display_date(iso_date: str) -> str:
    try:
        value = date.fromisoformat(iso_date)
    except ValueError:
        return iso_date
    return f"{MONTH_NAMES[value.month - 1]} {value.day}, {value.year}"


def build_typst_inputs(build_date: BuildDateContext) -> dict[str, str]:
    return {
        "build_date": build_date.display,
        "build_date_iso": build_date.iso,
    }


def load_existing_meta_date(out_dir: Path) -> str | None:
    meta_path = out_dir / "meta.json"
    if not meta_path.exists():
        return None

    try:
        data = json.loads(meta_path.read_text(encoding="utf-8"))
    except Exception:
        return None

    raw = str(data.get("date") or "").strip()
    return raw or None


def resolve_output_date(*, row: Row, build_date: BuildDateContext, existing_date: str | None, typst_date_mode: str) -> str:
    if typst_date_mode == "first-publish":
        return existing_date or build_date.iso

    value = row.date.strip()
    if value.lower() in AUTO_DATE_WORDS:
        return build_date.iso
    return value


def resolve_typst_date_override(*, build_date: BuildDateContext, existing_date: str | None, typst_date_mode: str) -> str | None:
    if typst_date_mode == "source":
        return None
    if typst_date_mode == "today":
        return build_date.display
    if typst_date_mode == "first-publish":
        return build_date.display if not existing_date else format_display_date(existing_date)
    raise SystemExit(f"Unsupported --typst-date-mode: {typst_date_mode}")


def replace_typst_date_field(source_text: str, display_date: str) -> str:
    lines = source_text.splitlines(keepends=True)
    for index, line in enumerate(lines):
        stripped = line.lstrip()
        if not stripped.startswith("date:"):
            continue

        indent = line[: len(line) - len(stripped)]
        newline = "\n" if line.endswith("\n") else ""
        lines[index] = f'{indent}date: "{display_date}",{newline}'
        return "".join(lines)
    return source_text


def sync_typst_source_date(*, typ_path: Path, display_date: str | None, existing_date: str | None, enabled: bool, typst_date_mode: str) -> bool:
    if not enabled or typst_date_mode != "first-publish" or existing_date or not display_date:
        return False

    original = typ_path.read_text(encoding="utf-8")
    patched = replace_typst_date_field(original, display_date)
    if patched == original:
        return False

    typ_path.write_text(patched, encoding="utf-8")
    return True


def prepare_compile_source(*, typ_path: Path, typst_date_override: str | None) -> tuple[Path, Path | None]:
    if not typst_date_override:
        return typ_path, None

    original = typ_path.read_text(encoding="utf-8")
    patched = replace_typst_date_field(original, typst_date_override)
    if patched == original:
        return typ_path, None

    with tempfile.NamedTemporaryFile(
        "w",
        encoding="utf-8",
        suffix=typ_path.suffix,
        prefix=f".{typ_path.stem}.build-",
        dir=typ_path.parent,
        delete=False,
    ) as tf:
        tf.write(patched)
        temp_path = Path(tf.name)

    return temp_path, temp_path


def collect_local_font_paths(font_roots: tuple[Path, ...]) -> list[Path]:
    font_dirs: set[Path] = set()
    for fonts_root in font_roots:
        if not fonts_root.exists():
            continue
        font_dirs.update(
            path.parent
            for path in fonts_root.rglob("*")
            if path.is_file() and path.suffix.lower() in FONT_FILE_SUFFIXES
        )
    return sorted(font_dirs)


def sync_web_fonts() -> None:
    docs_fonts_root = DOCS / "assets" / "fonts"
    if docs_fonts_root.exists():
        shutil.rmtree(docs_fonts_root)
    docs_fonts_root.mkdir(parents=True, exist_ok=True)

    for directory_name, file_names in WEB_FONT_ASSETS:
        source_dir = ROOT / "fonts" / directory_name
        if not source_dir.exists():
            raise SystemExit(f"Missing font directory: {source_dir}")
        target_dir = docs_fonts_root / directory_name
        target_dir.mkdir(parents=True, exist_ok=True)
        for file_name in file_names:
            source_file = source_dir / file_name
            if not source_file.exists():
                raise SystemExit(f"Missing font asset: {source_file}")
            shutil.copy2(source_file, target_dir / file_name)


def compile_typst_to_pdf(
    *,
    typ_path: Path,
    out_pdf: Path,
    typst_root: Path | None,
    typst_date_override: str | None,
    typst_inputs: dict[str, str],
) -> None:
    out_pdf.parent.mkdir(parents=True, exist_ok=True)
    if typst_root is not None:
        root = typst_root
    else:
        try:
            typ_path.relative_to(INCOMING_TYP)
            root = INCOMING_TYP
        except ValueError:
            root = typ_path.parent

    compile_path, temp_source = prepare_compile_source(typ_path=typ_path, typst_date_override=typst_date_override)

    deps_path = None
    try:
        with tempfile.NamedTemporaryFile(prefix="typst-deps-", suffix=".txt", delete=False) as tf:
            deps_path = Path(tf.name)

        cmd = ["typst", "compile", "--deps", str(deps_path), "--root", str(root)]
        for font_path in collect_local_font_paths(LOCAL_FONT_ROOTS):
            cmd.extend(["--font-path", str(font_path)])
        for key, value in typst_inputs.items():
            cmd.extend(["--input", f"{key}={value}"])
        cmd.extend([str(compile_path), str(out_pdf)])
        subprocess.run(cmd, check=True)

        enforce_images_location(deps_path=deps_path, root=root)
    finally:
        if deps_path is not None:
            try:
                deps_path.unlink(missing_ok=True)
            except Exception:
                pass
        if temp_source is not None:
            try:
                temp_source.unlink(missing_ok=True)
            except Exception:
                pass


def extract_typst_dependency_entries(raw_text: str) -> list[str]:
    stripped = raw_text.strip()
    if not stripped:
        return []

    try:
        payload = json.loads(stripped)
    except json.JSONDecodeError:
        payload = None
    else:
        entries: list[str] = []

        def collect(value: object) -> None:
            if isinstance(value, str):
                entries.append(value)
                return
            if isinstance(value, list):
                for item in value:
                    collect(item)
                return
            if isinstance(value, dict):
                for key in ("inputs", "dependencies", "files"):
                    if key in value:
                        collect(value[key])

        collect(payload)
        if entries:
            return entries

    if "\0" in raw_text:
        return [item.strip() for item in raw_text.split("\0") if item.strip()]

    return [line.strip() for line in raw_text.splitlines() if line.strip()]


def enforce_images_location(*, deps_path: Path, root: Path) -> None:
    """
    Enforce: all non-.typ dependencies that live under incoming/typst/ must be
    placed under a `images/` directory under incoming/typst/ (supports multi-level).

    Typst's `--deps` output format changed in newer releases and may now be JSON
    instead of a plain newline-delimited list. We accept both formats here.
    """
    typ_root = INCOMING_TYP.resolve()

    raw_text = deps_path.read_text(encoding="utf-8", errors="replace")
    for raw in extract_typst_dependency_entries(raw_text):
        p = Path(raw)
        if not p.is_absolute():
            p = (root / p).resolve()
        else:
            p = p.resolve()

        try:
            rel = p.relative_to(typ_root)
        except ValueError:
            continue

        if p.suffix.lower() == ".typ":
            continue

        if "images" not in rel.parts:
            raise SystemExit(
                "Typst 附件位置不符合约定：\n"
                f"- 发现依赖文件：{p}\n"
                "- 但它不在：incoming/typst/**/images/**\n"
                "请把所有图片/附件移动到某个分类目录下的 images/ 目录（支持多级目录），并在 Typst 中用相对路径引用。"
            )


def derive_categories_from_typst_path(*, typ_path: Path) -> list[str]:
    """
    Derive a single multi-level category path from a source file location under a base root.

    Example:
      incoming/typst/Computer Science/DSA/CS61B2025/notes/lec01.typ
      -> ["Computer Science/DSA/CS61B2025/notes"]

    The `images/` directory (and anything under it) is ignored.
    """
    try:
        rel = typ_path.resolve().relative_to(INCOMING_TYP.resolve())
    except ValueError:
        raise SystemExit(
            "Cannot auto-derive categories because the source file is not under expected directory:\n"
            f"- typ_file resolved to: {typ_path}\n"
            f"- expected under: {INCOMING_TYP}\n"
            "Move the file under the expected directory structure."
        )

    parent = rel.parent
    if str(parent) in (".", ""):
        return ["Uncategorized"]

    parts = [p for p in parent.parts if p and p != "."]
    if "images" in parts:
        parts = parts[: parts.index("images")]

    cat = "/".join(parts).strip()
    if not cat:
        return ["Uncategorized"]
    return [cat]


def write_meta(*, out_dir: Path, row: Row, categories: list[str], date_value: str) -> None:
    meta = {
        "id": row.slug,
        "title": row.title,
        "date": date_value,
        "categories": categories,
        "path": f"articles/{row.slug}/doc.pdf",
    }
    if row.excerpt:
        meta["excerpt"] = row.excerpt
    if row.tags:
        meta["tags"] = list(row.tags)
    (out_dir / "meta.json").write_text(json.dumps(meta, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    ns = parse_args()
    sync_web_fonts()
    manifest = Path(ns.manifest).resolve()
    rows = read_manifest(manifest)

    typst_root = Path(ns.typst_root).resolve() if ns.typst_root else None
    build_date = get_build_date_context(ns.build_timezone)
    typst_inputs = build_typst_inputs(build_date)

    for row in rows:
        out_dir = ARTICLES / row.slug
        out_dir.mkdir(parents=True, exist_ok=True)
        out_pdf = out_dir / "doc.pdf"

        typ_file_norm = row.typ_file.replace("\\", "/")
        typ_path = (INCOMING_TYP / typ_file_norm).resolve()
        if not typ_path.exists():
            typ_path = Path(typ_file_norm).resolve()
        if not typ_path.exists():
            raise SystemExit(f"Typst source not found for slug={row.slug}: {row.typ_file}")

        categories = derive_categories_from_typst_path(typ_path=typ_path)
        existing_date = load_existing_meta_date(out_dir)
        effective_date = resolve_output_date(
            row=row,
            build_date=build_date,
            existing_date=existing_date,
            typst_date_mode=ns.typst_date_mode,
        )
        typst_date_override = resolve_typst_date_override(
            build_date=build_date,
            existing_date=existing_date,
            typst_date_mode=ns.typst_date_mode,
        )
        sync_typst_source_date(
            typ_path=typ_path,
            display_date=typst_date_override,
            existing_date=existing_date,
            enabled=ns.sync_typst_source_date,
            typst_date_mode=ns.typst_date_mode,
        )

        if ns.skip_compile:
            if not out_pdf.exists():
                raise SystemExit(
                    f"--skip-compile set but output PDF not found for slug={row.slug}: {out_pdf}\n"
                    "Either remove --skip-compile, or pre-generate the PDF at the expected path."
                )
        else:
            compile_typst_to_pdf(
                typ_path=typ_path,
                out_pdf=out_pdf,
                typst_root=typst_root,
                typst_date_override=typst_date_override,
                typst_inputs=typst_inputs,
            )

        write_meta(out_dir=out_dir, row=row, categories=categories, date_value=effective_date)

    if not ns.skip_index:
        subprocess.run(["python3", str(ROOT / "scripts" / "build_posts_index.py")], check=True)

    print(f"Published {len(rows)} post(s).")


if __name__ == "__main__":
    main()
