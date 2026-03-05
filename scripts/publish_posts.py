#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
ARTICLES = DOCS / "articles"
INCOMING = ROOT / "incoming"
INCOMING_TYP = INCOMING / "typst"
MANIFEST = INCOMING / "manifest.csv"


@dataclass(frozen=True)
class Row:
    typ_file: str
    slug: str
    title: str
    date: str
    excerpt: str


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Publish posts from incoming Typst sources (Typst→PDF) into docs/ and rebuild index.")
    p.add_argument("--manifest", default=str(MANIFEST), help="CSV manifest path (default: incoming/manifest.csv)")
    p.add_argument("--typst-root", default="", help="Pass as --root to typst compile (default: each .typ parent)")
    p.add_argument("--skip-compile", action="store_true", help="Skip Typst compilation (assume docs/articles/<slug>/doc.pdf already exists)")
    p.add_argument("--skip-index", action="store_true", help="Skip regenerating docs/data/posts.json")
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
            # Allow comment lines starting with '#' in the first column (typ_file).
            # This keeps it convenient to put examples directly inside manifest.csv.
            first = (rec.get("typ_file") or "").strip()
            if first.startswith("#"):
                continue

            # Skip completely empty rows.
            if not any((rec.get(k) or "").strip() for k in (reader.fieldnames or [])):
                continue

            typ_file = (rec.get("typ_file") or "").strip()
            slug = (rec.get("slug") or "").strip()
            title = (rec.get("title") or "").strip()
            date = (rec.get("date") or "").strip()
            excerpt = (rec.get("excerpt") or "").strip()

            if not slug:
                raise SystemExit(f"Line {i}: empty slug")
            if not title:
                raise SystemExit(f"Line {i}: empty title for slug={slug}")
            if not date:
                raise SystemExit(f"Line {i}: empty date for slug={slug}")
            if not typ_file:
                raise SystemExit(f"Line {i}: typ_file required (Typst-only mode) for slug={slug}")

            rows.append(Row(typ_file=typ_file, slug=slug, title=title, date=date, excerpt=excerpt))

    slugs = [r.slug for r in rows]
    if len(slugs) != len(set(slugs)):
        dupes = sorted({s for s in slugs if slugs.count(s) > 1})
        raise SystemExit(f"Duplicate slug(s): {', '.join(dupes)}")
    return rows


def compile_typst_to_pdf(*, typ_path: Path, out_pdf: Path, typst_root: Path | None) -> None:
    out_pdf.parent.mkdir(parents=True, exist_ok=True)
    if typst_root is not None:
        root = typst_root
    else:
        # If the Typst source lives under incoming/typst, prefer that as project root.
        # This makes it easy to share images across a course folder via absolute paths
        # (paths starting with `/` in Typst).
        try:
            typ_path.relative_to(INCOMING_TYP)
            root = INCOMING_TYP
        except ValueError:
            root = typ_path.parent

    deps_path = None
    try:
        with tempfile.NamedTemporaryFile(prefix="typst-deps-", suffix=".txt", delete=False) as tf:
            deps_path = Path(tf.name)

        cmd = ["typst", "compile", "--deps", str(deps_path), "--root", str(root), str(typ_path), str(out_pdf)]
        subprocess.run(cmd, check=True)

        enforce_images_location(deps_path=deps_path, root=root)
    finally:
        if deps_path is not None:
            try:
                deps_path.unlink(missing_ok=True)
            except Exception:
                pass


def enforce_images_location(*, deps_path: Path, root: Path) -> None:
    """
    Enforce: all non-.typ dependencies that live under incoming/typst/ must be
    placed under a `images/` directory under incoming/typst/ (supports multi-level).
    """
    typ_root = INCOMING_TYP.resolve()

    text = deps_path.read_text(encoding="utf-8", errors="replace")
    for raw in text.splitlines():
        raw = raw.strip()
        if not raw:
            continue

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


def write_meta(*, out_dir: Path, row: Row, categories: list[str]) -> None:
    meta = {
        "id": row.slug,
        "title": row.title,
        "date": row.date,
        "categories": categories,
        "path": f"articles/{row.slug}/doc.pdf",
    }
    if row.excerpt:
        meta["excerpt"] = row.excerpt
    (out_dir / "meta.json").write_text(json.dumps(meta, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    ns = parse_args()
    manifest = Path(ns.manifest).resolve()
    rows = read_manifest(manifest)

    typst_root = Path(ns.typst_root).resolve() if ns.typst_root else None

    for row in rows:
        out_dir = ARTICLES / row.slug
        out_dir.mkdir(parents=True, exist_ok=True)
        out_pdf = out_dir / "doc.pdf"
        categories: list[str] = []

        typ_file_norm = row.typ_file.replace("\\", "/")
        typ_path = (INCOMING_TYP / typ_file_norm).resolve()
        if not typ_path.exists():
            typ_path = Path(typ_file_norm).resolve()
        if not typ_path.exists():
            raise SystemExit(f"Typst source not found for slug={row.slug}: {row.typ_file}")

        categories = derive_categories_from_typst_path(typ_path=typ_path)

        if ns.skip_compile:
            if not out_pdf.exists():
                raise SystemExit(
                    f"--skip-compile set but output PDF not found for slug={row.slug}: {out_pdf}\n"
                    "Either remove --skip-compile, or pre-generate the PDF at the expected path."
                )
        else:
            compile_typst_to_pdf(typ_path=typ_path, out_pdf=out_pdf, typst_root=typst_root)

        write_meta(out_dir=out_dir, row=row, categories=categories)

    if not ns.skip_index:
        subprocess.run(["python3", str(ROOT / "scripts" / "build_posts_index.py")], check=True)

    print(f"Published {len(rows)} post(s).")


if __name__ == "__main__":
    main()
