#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
import shutil
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
ARTICLES = DOCS / "articles"
INCOMING = ROOT / "incoming"
INCOMING_PDFS = INCOMING / "pdfs"
INCOMING_TYP = INCOMING / "typst"
MANIFEST = INCOMING / "manifest.csv"


@dataclass(frozen=True)
class Row:
    pdf_file: str
    typ_file: str
    slug: str
    title: str
    date: str
    categories: list[str]
    excerpt: str


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Publish posts from incoming sources (Typst→PDF or PDF) into docs/ and rebuild index.")
    p.add_argument("--manifest", default=str(MANIFEST), help="CSV manifest path (default: incoming/manifest.csv)")
    p.add_argument("--typst-root", default="", help="Pass as --root to typst compile (default: each .typ parent)")
    p.add_argument("--skip-compile", action="store_true", help="Skip Typst compilation (assume PDFs already provided)")
    p.add_argument("--skip-index", action="store_true", help="Skip regenerating docs/data/posts.json")
    return p.parse_args()


def split_categories(raw: str) -> list[str]:
    items = [x.strip() for x in raw.split(",")]
    items = [x for x in items if x]
    if not items:
        raise SystemExit("Empty categories")
    return items


def read_manifest(path: Path) -> list[Row]:
    if not path.exists():
        raise SystemExit(f"Manifest not found: {path}")

    rows: list[Row] = []
    with path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        required = {"slug", "title", "date", "categories"}
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

            pdf_file = (rec.get("pdf_file") or "").strip()
            typ_file = (rec.get("typ_file") or "").strip()
            slug = (rec.get("slug") or "").strip()
            title = (rec.get("title") or "").strip()
            date = (rec.get("date") or "").strip()
            cats = split_categories((rec.get("categories") or "").strip())
            excerpt = (rec.get("excerpt") or "").strip()

            if not slug:
                raise SystemExit(f"Line {i}: empty slug")
            if not title:
                raise SystemExit(f"Line {i}: empty title for slug={slug}")
            if not date:
                raise SystemExit(f"Line {i}: empty date for slug={slug}")
            if not (typ_file or pdf_file):
                raise SystemExit(f"Line {i}: need typ_file or pdf_file for slug={slug}")

            rows.append(Row(pdf_file=pdf_file, typ_file=typ_file, slug=slug, title=title, date=date, categories=cats, excerpt=excerpt))

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
    placed under incoming/typst/images/.
    """
    images_root = (INCOMING_TYP / "images").resolve()

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
            p.relative_to(INCOMING_TYP.resolve())
        except ValueError:
            continue

        if p.suffix.lower() == ".typ":
            continue

        try:
            p.relative_to(images_root)
        except ValueError as e:
            raise SystemExit(
                "Typst 附件位置不符合约定：\n"
                f"- 发现依赖文件：{p}\n"
                f"- 但它不在：{images_root}\n"
                "请把所有图片/附件移动到 incoming/typst/images/ 下，并在 Typst 中用 /images/... 引用。"
            ) from e


def write_meta(*, out_dir: Path, row: Row) -> None:
    meta = {
        "id": row.slug,
        "title": row.title,
        "date": row.date,
        "categories": row.categories,
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

        if row.typ_file and not ns.skip_compile:
            typ_path = (INCOMING_TYP / row.typ_file).resolve()
            if not typ_path.exists():
                typ_path = Path(row.typ_file).resolve()
            if not typ_path.exists():
                raise SystemExit(f"Typst source not found for slug={row.slug}: {row.typ_file}")
            compile_typst_to_pdf(typ_path=typ_path, out_pdf=out_pdf, typst_root=typst_root)
        else:
            pdf_path = (INCOMING_PDFS / row.pdf_file).resolve()
            if not pdf_path.exists():
                pdf_path = Path(row.pdf_file).resolve()
            if not pdf_path.exists():
                raise SystemExit(f"PDF not found for slug={row.slug}: {row.pdf_file}")
            shutil.copyfile(pdf_path, out_pdf)

        write_meta(out_dir=out_dir, row=row)

    if not ns.skip_index:
        subprocess.run(["python3", str(ROOT / "scripts" / "build_posts_index.py")], check=True)

    print(f"Published {len(rows)} post(s).")


if __name__ == "__main__":
    main()
