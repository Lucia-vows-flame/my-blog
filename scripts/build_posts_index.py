#!/usr/bin/env python3
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
ARTICLES = DOCS / "articles"
OUT = DOCS / "data" / "posts.json"


@dataclass(frozen=True)
class Post:
    id: str
    title: str
    date: str
    categories: list[str]
    path: str
    excerpt: str = ""
    tags: list[str] | None = None

    def to_json(self) -> dict[str, Any]:
        data: dict[str, Any] = {
            "id": self.id,
            "title": self.title,
            "date": self.date,
            "categories": self.categories,
            "path": self.path,
        }
        if self.excerpt:
            data["excerpt"] = self.excerpt
        if self.tags:
            data["tags"] = self.tags
        return data


def read_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def load_posts() -> list[Post]:
    posts: list[Post] = []
    if not ARTICLES.exists():
        return posts

    for meta_path in sorted(ARTICLES.glob("**/meta.json")):
        data = read_json(meta_path)

        try:
            post_id = str(data["id"])
            title = str(data["title"])
            date = str(data["date"])
            path = str(data["path"])
        except KeyError as e:
            raise SystemExit(f"Missing required field {e} in {meta_path}") from e

        categories_raw = data.get("categories", data.get("category", []))
        if isinstance(categories_raw, str):
            categories = [categories_raw]
        elif isinstance(categories_raw, list) and all(isinstance(x, str) for x in categories_raw):
            categories = list(categories_raw)
        else:
            raise SystemExit(f"Invalid categories in {meta_path}: expected string or string[]")

        tags_raw = data.get("tags", [])
        if isinstance(tags_raw, str):
            tags = [tags_raw] if tags_raw else []
        elif isinstance(tags_raw, list) and all(isinstance(x, str) for x in tags_raw):
            tags = [str(x) for x in tags_raw if str(x).strip()]
        else:
            raise SystemExit(f"Invalid tags in {meta_path}: expected string or string[]")

        excerpt = str(data.get("excerpt", "") or "")
        posts.append(Post(id=post_id, title=title, date=date, categories=categories, path=path, excerpt=excerpt, tags=tags))

    ids = [p.id for p in posts]
    if len(ids) != len(set(ids)):
        dupes = sorted({x for x in ids if ids.count(x) > 1})
        raise SystemExit(f"Duplicate post id(s): {', '.join(dupes)}")

    return posts


def main() -> None:
    posts = load_posts()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps({"posts": [p.to_json() for p in posts]}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {OUT} ({len(posts)} posts)")


if __name__ == "__main__":
    main()

