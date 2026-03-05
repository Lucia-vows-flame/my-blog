const POSTS_URL = "data/posts.json";

function routeToPost({ id, path }) {
  const params = new URLSearchParams();
  if (id) params.set("id", id);
  if (path) params.set("path", path);
  location.hash = params.toString();
}

function qs(id) {
  return document.getElementById(id);
}

function parseHashParams() {
  const raw = (location.hash || "").replace(/^#/, "");
  const params = new URLSearchParams(raw);
  return Object.fromEntries(params.entries());
}

function toAbsoluteUrl(href, base) {
  try {
    return new URL(href, base);
  } catch {
    return null;
  }
}

function normalizeCategoryPath(raw) {
  if (typeof raw !== "string") return "";
  const s = raw.trim().replaceAll("\\", "/");
  const parts = s.split("/").map((x) => x.trim()).filter(Boolean);
  return parts.join("/");
}

function splitCategoryPath(path) {
  const p = normalizeCategoryPath(path);
  return p ? p.split("/") : [];
}

function formatDate(iso) {
  const date = new Date(iso);
  if (Number.isNaN(date.valueOf())) return iso;
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}.${m}.${d}`;
}

function byDateDesc(a, b) {
  return new Date(b.date).valueOf() - new Date(a.date).valueOf();
}

function normalizePost(raw) {
  const categoriesRaw = Array.isArray(raw.categories)
    ? raw.categories
    : typeof raw.category === "string"
      ? [raw.category]
      : [];
  const categories = categoriesRaw.map(normalizeCategoryPath).filter(Boolean);
  return {
    id: String(raw.id || raw.path || raw.title || Math.random()),
    title: String(raw.title || "Untitled"),
    date: String(raw.date || "1970-01-01"),
    path: String(raw.path || ""),
    categories,
    excerpt: typeof raw.excerpt === "string" ? raw.excerpt : "",
  };
}

function buildCategoryTree(posts) {
  /** @type {{name: string, path: string, count: number, children: Map<string, any>}} */
  const root = { name: "", path: "", count: 0, children: new Map() };

  for (const post of posts) {
    const uniq = new Set(post.categories);
    for (const catPath of uniq) {
      const parts = splitCategoryPath(catPath);
      if (!parts.length) continue;

      let cur = root;
      let acc = "";
      for (const part of parts) {
        acc = acc ? `${acc}/${part}` : part;
        let child = cur.children.get(part);
        if (!child) {
          child = { name: part, path: acc, count: 0, children: new Map() };
          cur.children.set(part, child);
        }
        child.count += 1;
        cur = child;
      }
    }
  }

  return root;
}

function compareCatNode(a, b) {
  return b.count - a.count || a.name.localeCompare(b.name);
}

function getFirstCategoryPath(root) {
  const top = [...root.children.values()].sort(compareCatNode)[0];
  return top?.path || "";
}

function getExpandedDefaults({ root, activeCategory }) {
  /** @type {Set<string>} */
  const expanded = new Set();

  // Expand top-level by default (so users can discover deeper categories).
  for (const child of root.children.values()) {
    expanded.add(child.path);
  }

  // Expand all ancestors of active category.
  if (activeCategory) {
    const parts = splitCategoryPath(activeCategory);
    let acc = "";
    for (let i = 0; i < parts.length - 1; i += 1) {
      acc = acc ? `${acc}/${parts[i]}` : parts[i];
      expanded.add(acc);
    }
  }

  // Merge with saved toggles.
  for (const path of allCategoryPaths(root)) {
    const key = `cat.expanded:${path}`;
    const v = safeLocalStorageGet(key);
    if (v === "1") expanded.add(path);
    if (v === "0") expanded.delete(path);
  }

  return expanded;
}

function* allCategoryPaths(root) {
  /** @type {any[]} */
  const stack = [...root.children.values()];
  while (stack.length) {
    const node = stack.pop();
    yield node.path;
    for (const c of node.children.values()) stack.push(c);
  }
}

function isActiveOrAncestor({ activeCategory, nodePath }) {
  if (!activeCategory) return false;
  if (activeCategory === nodePath) return true;
  return activeCategory.startsWith(`${nodePath}/`);
}

function safeLocalStorageGet(key) {
  try {
    return localStorage.getItem(key);
  } catch {
    return null;
  }
}

function safeLocalStorageSet(key, value) {
  try {
    localStorage.setItem(key, value);
  } catch {
    // ignore
  }
}

function renderCategories({ root, activeCategory }) {
  const el = qs("cat-list");
  if (!el) return;
  el.innerHTML = "";

  const expanded = getExpandedDefaults({ root, activeCategory });

  const renderNode = (node, level) => {
    const li = document.createElement("li");
    li.className = "cat-item";
    li.style.setProperty("--level", String(level));

    const row = document.createElement("div");
    row.className = "cat-row";

    const toggle = document.createElement("button");
    toggle.className = "cat-toggle";
    const hasChildren = node.children.size > 0;
    toggle.disabled = !hasChildren;

    const link = document.createElement("a");
    link.className = "cat-link";
    link.href = `category.html#c=${encodeURIComponent(node.path)}`;

    if (activeCategory && activeCategory === node.path) link.classList.add("is-active");
    else if (isActiveOrAncestor({ activeCategory, nodePath: node.path })) link.classList.add("is-active-ancestor");

    const name = document.createElement("span");
    name.className = "cat-name";
    name.textContent = node.name;

    const count = document.createElement("span");
    count.className = "cat-count";
    count.textContent = `(${node.count})`;

    link.append(name, count);

    let childList = null;
    const isExpanded = expanded.has(node.path);
    if (hasChildren) {
      toggle.textContent = isExpanded ? "▾" : "▸";
      toggle.setAttribute("aria-label", isExpanded ? "Collapse" : "Expand");

      toggle.addEventListener("click", (ev) => {
        ev.preventDefault();
        ev.stopPropagation();
        const next = !expanded.has(node.path);
        if (next) expanded.add(node.path);
        else expanded.delete(node.path);
        safeLocalStorageSet(`cat.expanded:${node.path}`, next ? "1" : "0");
        toggle.textContent = next ? "▾" : "▸";
        toggle.setAttribute("aria-label", next ? "Collapse" : "Expand");
        if (childList) childList.hidden = !next;
      });
    } else {
      toggle.textContent = "";
      toggle.setAttribute("aria-hidden", "true");
    }

    row.append(toggle, link);
    li.append(row);

    if (hasChildren) {
      childList = document.createElement("ul");
      childList.className = "cat-children";
      childList.hidden = !isExpanded;

      const children = [...node.children.values()].sort(compareCatNode);
      for (const child of children) childList.append(renderNode(child, level + 1));
      li.append(childList);
    }

    return li;
  };

  const top = [...root.children.values()].sort(compareCatNode);
  for (const node of top) el.append(renderNode(node, 0));
}

function postLink(post) {
  return `post.html#id=${encodeURIComponent(post.id)}`;
}

function renderLatest(posts) {
  const list = qs("latest-list");
  const meta = qs("latest-meta");
  if (!list) return;

  const latest = [...posts].sort(byDateDesc).slice(0, 20);
  if (meta) meta.textContent = `最近的${latest.length}篇文章（共${posts.length}篇）`;

  list.innerHTML = "";
  for (const post of latest) {
    const li = document.createElement("li");

    const date = document.createElement("div");
    date.className = "post-date";
    date.textContent = formatDate(post.date);

    const title = document.createElement("a");
    title.className = "post-title";
    title.href = postLink(post);
    title.textContent = post.title;

    li.append(date, title);
    list.append(li);
  }
}

function groupByYear(posts) {
  /** @type {Map<number, any[]>} */
  const m = new Map();
  for (const post of posts) {
    const y = new Date(post.date).getFullYear();
    const year = Number.isFinite(y) ? y : 1970;
    const arr = m.get(year) || [];
    arr.push(post);
    m.set(year, arr);
  }
  return [...m.entries()]
    .sort((a, b) => b[0] - a[0])
    .map(([year, items]) => ({ year, items: items.sort(byDateDesc) }));
}

function renderCategory(posts, category) {
  const title = qs("cat-title");
  const meta = qs("cat-meta");
  const groups = qs("cat-groups");
  if (!groups) return;

  const cat = normalizeCategoryPath(category);
  const prefix = cat ? `${cat}/` : "";
  const filtered = posts.filter((p) => p.categories.some((c) => c === cat || (prefix && c.startsWith(prefix))));
  if (title) title.textContent = `分类：${cat}`;
  if (meta) meta.textContent = `（共${filtered.length}篇文章）`;

  groups.innerHTML = "";
  const yearGroups = groupByYear(filtered);

  for (const g of yearGroups) {
    const wrap = document.createElement("section");
    wrap.className = "year-group";

    const h = document.createElement("h2");
    h.className = "year-title";
    h.textContent = `${g.year}年`;

    const ul = document.createElement("ul");
    for (const post of g.items) {
      const li = document.createElement("li");
      const a = document.createElement("a");
      a.href = postLink(post);
      a.textContent = `${post.title}（${formatDate(post.date)}）`;
      li.append(a);
      ul.append(li);
    }

    wrap.append(h, ul);
    groups.append(wrap);
  }
}

function decorateIframeLinks(frame, posts) {
  const onLoad = () => {
    let doc;
    try {
      doc = frame.contentDocument;
    } catch {
      return;
    }
    if (!doc) return;

    for (const a of doc.querySelectorAll("a[href]")) {
      const href = a.getAttribute("href") || "";
      const abs = toAbsoluteUrl(href, doc.baseURI);
      if (!abs) continue;
      if (abs.origin !== location.origin) {
        a.setAttribute("target", "_blank");
        a.setAttribute("rel", "noopener noreferrer");
      }
    }

    doc.addEventListener(
      "click",
      (ev) => {
        const target = ev.target;
        if (!(target instanceof Element)) return;
        const a = target.closest("a[href]");
        if (!a) return;
        const href = a.getAttribute("href") || "";

        const abs = toAbsoluteUrl(href, doc.baseURI);
        if (!abs) return;
        if (abs.origin !== location.origin) return;

        const siteRoot = new URL("/", location.href);
        let relPath = abs.pathname.replace(siteRoot.pathname, "");
        relPath = relPath.replace(/^\//, "");

        const match = posts.find((p) => p.path === relPath);
        if (match) {
          ev.preventDefault();
          routeToPost({ id: match.id });
          return;
        }

        if (relPath.startsWith("articles/") && relPath.endsWith(".html")) {
          ev.preventDefault();
          routeToPost({ path: relPath });
        }
      },
      { capture: true },
    );
  };

  frame.addEventListener("load", onLoad);
}

function renderPost(posts, { postId, postPath }) {
  const post = postId ? posts.find((p) => p.id === postId) : posts.find((p) => p.path === postPath);
  const title = qs("post-title");
  const meta = qs("post-meta");
  const frame = qs("post-frame");
  if (!frame) return;

  if (!post) {
    if (title) title.textContent = "文章不存在";
    if (meta) meta.textContent = "";
    frame.removeAttribute("src");
    frame.srcdoc = `<div style="padding:16px;font:16px/1.6 system-ui">找不到文章：<code>${postId || postPath || ""}</code></div>`;
    return;
  }

  document.title = post.title;
  if (title) title.textContent = post.title;

  if (meta) {
    const cats = post.categories.map((c) => categoryBreadcrumbLinks(c)).join(" | ");
    const open = `<a href="${post.path}" target="_blank" rel="noopener noreferrer">新窗口打开</a>`;
    const download = post.path.toLowerCase().endsWith(".pdf")
      ? ` · <a href="${post.path}" download>下载 PDF</a>`
      : "";
    meta.innerHTML = `${formatDate(post.date)} · ${cats} · ${open}${download}`;
  }

  frame.src = post.path;
}

function escapeHtml(s) {
  return String(s)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function categoryBreadcrumbLinks(path) {
  const parts = splitCategoryPath(path);
  let acc = "";
  return parts
    .map((part) => {
      acc = acc ? `${acc}/${part}` : part;
      return `<a href="category.html#c=${encodeURIComponent(acc)}">${escapeHtml(part)}</a>`;
    })
    .join(" / ");
}

function route({ posts, categories }) {
  const hash = parseHashParams();
  let activeCategory = normalizeCategoryPath(hash.c || "");

  const isPostPage = Boolean(qs("post-frame"));
  const isCategoryPage = Boolean(qs("cat-groups"));

  const postId = hash.id || "";
  const postPath = hash.path || "";

  if (isPostPage && !activeCategory && (postId || postPath)) {
    const post = postId ? posts.find((p) => p.id === postId) : posts.find((p) => p.path === postPath);
    activeCategory = post?.categories?.[0] || activeCategory;
  }

  renderCategories({ root: categories, activeCategory });

  if (qs("latest-list")) {
    renderLatest(posts);
  }

  if (isCategoryPage) {
    const category = activeCategory || getFirstCategoryPath(categories);
    if (category) renderCategory(posts, category);
  }

  if (isPostPage) {
    if (postId || postPath) renderPost(posts, { postId, postPath });
  }
}

async function main() {
  const res = await fetch(POSTS_URL, { cache: "no-store" });
  if (!res.ok) throw new Error(`Failed to load ${POSTS_URL}: ${res.status}`);
  const data = await res.json();
  const posts = (data.posts || []).map(normalizePost);
  const categories = buildCategoryTree(posts);

  const frame = qs("post-frame");
  if (frame) decorateIframeLinks(frame, posts);

  route({ posts, categories });
  window.addEventListener("hashchange", () => route({ posts, categories }));
}

main().catch((err) => {
  console.error(err);
  const container = qs("latest-list") || qs("cat-groups");
  if (container) {
    container.innerHTML =
      `<div style="padding:10px;color:rgba(20,20,20,.7)">` +
      `加载数据失败：<code>${String(err.message || err)}</code><br/>` +
      `请用本地 HTTP 服务预览，或检查 <code>${POSTS_URL}</code> 路径。` +
      `</div>`;
  }
});
