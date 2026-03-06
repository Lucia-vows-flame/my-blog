const POSTS_URL = "data/posts.json";
const PDF_VIEWER_VERSION = "20260305i";
const PDF_VIEWER = `pdf.html?v=${PDF_VIEWER_VERSION}`;
let didInitialRoute = false;

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

function isPdfPost(post) {
  return String(post?.path || "").toLowerCase().endsWith(".pdf");
}

function pdfViewerUrl(pdfPath) {
  return `${PDF_VIEWER}#file=${encodeURIComponent(pdfPath)}`;
}

function buildCategoryTree(posts) {
  /** @type {{name: string, path: string, count: number, children: Map<string, any>, postIds: Set<string>}} */
  const root = { name: "", path: "", count: 0, children: new Map(), postIds: new Set() };

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
          child = { name: part, path: acc, count: 0, children: new Map(), postIds: new Set() };
          cur.children.set(part, child);
        }
        const postId = String(post.id);
        if (!child.postIds.has(postId)) {
          child.postIds.add(postId);
          child.count += 1;
        }
        cur = child;
      }
    }
  }

  return root;
}

function compareCatNode(a, b) {
  return b.count - a.count || a.name.localeCompare(b.name);
}

function categoryId(name) {
  return encodeURIComponent(String(name || "")).replaceAll("%", "_");
}

function topLevelFromPath(path) {
  return splitCategoryPath(path)[0] || "";
}

function countAllCategories(root) {
  let n = 0;
  for (const _ of allCategoryPaths(root)) n += 1;
  return n;
}

function hashHue(s) {
  let h = 0;
  for (const ch of String(s)) h = (h * 31 + ch.charCodeAt(0)) >>> 0;
  return h % 360;
}

function computeTopLevelPostCounts(posts) {
  /** @type {Map<string, number>} */
  const m = new Map();
  for (const post of posts) {
    /** @type {Set<string>} */
    const uniq = new Set();
    for (const c of post.categories) {
      const top = topLevelFromPath(c);
      if (top) uniq.add(top);
    }
    for (const top of uniq) m.set(top, (m.get(top) || 0) + 1);
  }
  return m;
}

function computePostsByExactCategory(posts) {
  /** @type {Map<string, any[]>} */
  const m = new Map();
  for (const post of posts) {
    const uniq = new Set(post.categories);
    for (const cat of uniq) {
      const key = normalizeCategoryPath(cat);
      if (!key) continue;
      const arr = m.get(key) || [];
      arr.push(post);
      m.set(key, arr);
    }
  }

  for (const arr of m.values()) arr.sort(byDateDesc);
  return m;
}

function getFirstCategoryPath(root) {
  const top = [...root.children.values()].sort(compareCatNode)[0];
  return top?.path || "";
}

function getIndexExpandedDefaults({ root, activeCategory }) {
  /** @type {Set<string>} */
  const expanded = new Set();

  // Expand top-level by default (so users can discover deeper categories).
  for (const child of root.children.values()) expanded.add(child.path);

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
    const key = `cat.index.expanded:${path}`;
    const v = safeLocalStorageGet(key);
    if (v === "1") expanded.add(path);
    if (v === "0") expanded.delete(path);
  }

  return expanded;
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
  if (isPdfPost(post)) return pdfViewerUrl(post.path);
  return `post.html#id=${encodeURIComponent(post.id)}`;
}

function renderCategoryIndex({ posts, root, activeCategory }) {
  const totalEl = qs("cat-total");
  const chipsEl = qs("cat-chips");
  const sectionsEl = qs("cat-sections");
  if (!chipsEl || !sectionsEl) return;

  if (totalEl) totalEl.textContent = String(root.children.size);

  const topCounts = computeTopLevelPostCounts(posts);
  const postsByCat = computePostsByExactCategory(posts);
  const activeTop = topLevelFromPath(activeCategory);
  const expanded = getIndexExpandedDefaults({ root, activeCategory });

  chipsEl.innerHTML = "";
  const topNodes = [...root.children.values()].sort(compareCatNode);
  for (const node of topNodes) {
    const chip = document.createElement("a");
    chip.className = "cat-chip";
    chip.href = `#top=${encodeURIComponent(node.name)}`;
    chip.style.setProperty("--chip-h", String(hashHue(node.name)));
    if (node.name === activeTop) chip.classList.add("is-active");

    const hash = document.createElement("span");
    hash.className = "cat-chip__hash";
    hash.textContent = "#";

    const name = document.createElement("span");
    name.className = "cat-chip__name";
    name.textContent = node.name;

    const count = document.createElement("span");
    count.className = "cat-chip__count";
    count.textContent = `(${topCounts.get(node.name) || 0})`;

    chip.append(hash, name, count);
    chipsEl.append(chip);
  }

  sectionsEl.innerHTML = "";
  const box = document.createElement("div");
  box.className = "cat-indexBox";
  sectionsEl.append(box);

  const renderNode = (node, level) => {
    const li = document.createElement("li");
    li.className = "cat-indexItem";
    li.dataset.level = String(level);
    li.style.setProperty("--level", String(level));

    if (level === 0) li.id = `cat-top_${categoryId(node.name)}`;

    const row = document.createElement("div");
    row.className = "cat-indexRow";

    const toggle = document.createElement("button");
    toggle.type = "button";
    toggle.className = "cat-indexToggle";

    const directPosts = postsByCat.get(node.path) || [];
    const hasChildren = node.children.size > 0;
    const hasPosts = directPosts.length > 0;
    const expandable = hasChildren || hasPosts;

    toggle.disabled = !expandable;
    if (!expandable) {
      toggle.textContent = "";
      toggle.setAttribute("aria-hidden", "true");
    }

    const link = document.createElement("a");
    link.className = "cat-indexLink";
    link.href = `#c=${encodeURIComponent(node.path)}`;

    if (activeCategory && activeCategory === node.path) link.classList.add("is-active");
    else if (isActiveOrAncestor({ activeCategory, nodePath: node.path })) link.classList.add("is-active-ancestor");

    const nameWrap = document.createElement("span");
    nameWrap.className = "cat-indexNameWrap";

    const dot = document.createElement("span");
    dot.className = "cat-indexDot";
    dot.setAttribute("aria-hidden", "true");

    const name = document.createElement("span");
    name.className = "cat-indexName";
    name.textContent = node.name;

    nameWrap.append(dot, name);

    const count = document.createElement("span");
    count.className = "cat-indexCount";
    count.textContent = `(${node.count})`;

    link.append(nameWrap, count);
    row.append(toggle, link);
    li.append(row);

    if (!expandable) return li;

    const childrenWrap = document.createElement("div");
    childrenWrap.className = "cat-indexChildren";

    const isExpanded = expanded.has(node.path);
    childrenWrap.hidden = !isExpanded;
    toggle.textContent = isExpanded ? "▾" : "▸";
    toggle.setAttribute("aria-label", isExpanded ? "Collapse" : "Expand");
    toggle.setAttribute("aria-expanded", isExpanded ? "true" : "false");

    toggle.addEventListener("click", (ev) => {
      ev.preventDefault();
      ev.stopPropagation();
      const next = !expanded.has(node.path);
      if (next) expanded.add(node.path);
      else expanded.delete(node.path);
      safeLocalStorageSet(`cat.index.expanded:${node.path}`, next ? "1" : "0");
      toggle.textContent = next ? "▾" : "▸";
      toggle.setAttribute("aria-label", next ? "Collapse" : "Expand");
      toggle.setAttribute("aria-expanded", next ? "true" : "false");
      childrenWrap.hidden = !next;
    });

    if (hasChildren) {
      const ul = document.createElement("ul");
      ul.className = "cat-indexList";
      const children = [...node.children.values()].sort(compareCatNode);
      for (const child of children) ul.append(renderNode(child, level + 1));
      childrenWrap.append(ul);
    }

    if (hasPosts) {
      const ul = document.createElement("ul");
      ul.className = "cat-postList";
      ul.style.setProperty("--level", String(level + 1));
      for (const post of directPosts) {
        const item = document.createElement("li");
        item.className = "cat-postItem";

        const dot = document.createElement("span");
        dot.className = "cat-postDot";
        dot.setAttribute("aria-hidden", "true");

        const a = document.createElement("a");
        a.className = "cat-postLink";
        a.href = postLink(post);
        a.textContent = post.title;
        if (isPdfPost(post)) {
          a.target = "_blank";
          a.rel = "noopener noreferrer";
          a.title = "PDF 将在新窗口打开";
        }

        const date = document.createElement("span");
        date.className = "cat-postDate";
        date.textContent = formatDate(post.date);

        item.append(dot, a, date);
        ul.append(item);
      }
      childrenWrap.append(ul);
    }

    li.append(childrenWrap);
    return li;
  };

  const ul = document.createElement("ul");
  ul.className = "cat-indexList";
  for (const top of topNodes) ul.append(renderNode(top, 0));
  box.append(ul);
}

function renderLatest(posts) {
  const list = qs("latest-list");
  const meta = qs("latest-meta");
  if (!list) return;

  const latest = [...posts].sort(byDateDesc).slice(0, 20);
  if (meta) meta.textContent = `最近的${latest.length}篇文章（共${posts.length}篇）`;

  list.innerHTML = "";
  for (const post of latest) {
    const wrap = document.createElement("div");
    wrap.className = "post-preview";

    const a = document.createElement("a");
    a.href = postLink(post);
    if (isPdfPost(post)) {
      a.target = "_blank";
      a.rel = "noopener noreferrer";
      a.title = "PDF 将在新窗口打开";
    }

    const h2 = document.createElement("h2");
    h2.className = "post-title";
    h2.textContent = post.title;
    a.append(h2);

    if (post.excerpt) {
      const h3 = document.createElement("h3");
      h3.className = "post-subtitle";
      h3.textContent = post.excerpt;
      a.append(h3);
    }

    wrap.append(a);

    const cats = post.categories.map((c) => categoryBreadcrumbLinks(c)).join(" | ");
    const pm = document.createElement("p");
    pm.className = "post-meta";
    pm.innerHTML = `发表于 ${escapeHtml(formatDate(post.date))}${cats ? ` · ${cats}` : ""}`;
    wrap.append(pm);

    list.append(wrap);

    const hr = document.createElement("hr");
    hr.className = "my-4";
    list.append(hr);
  }

  const last = list.lastElementChild;
  if (last && last.tagName.toLowerCase() === "hr") last.remove();
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
  if (title) title.textContent = "ARTICLE";
  if (meta) meta.innerHTML = `${cat ? `分类：${categoryBreadcrumbLinks(cat)}` : "按分类浏览全部文章"}${`（共${filtered.length}篇文章）`}`;

  groups.innerHTML = "";
  const yearGroups = groupByYear(filtered);

  for (const g of yearGroups) {
    const h = document.createElement("h2");
    h.className = "blog-yearHeading";
    h.textContent = `${g.year}年`;
    groups.append(h);

    for (const post of g.items) {
      const wrap = document.createElement("div");
      wrap.className = "post-preview";

      const a = document.createElement("a");
      a.href = postLink(post);
      if (isPdfPost(post)) {
        a.target = "_blank";
        a.rel = "noopener noreferrer";
        a.title = "PDF 将在新窗口打开";
      }

      const h2 = document.createElement("h2");
      h2.className = "post-title";
      h2.textContent = post.title;
      a.append(h2);
      wrap.append(a);

      const cats = post.categories.map((c) => categoryBreadcrumbLinks(c)).join(" | ");
      const pm = document.createElement("p");
      pm.className = "post-meta";
      pm.innerHTML = `发表于 ${escapeHtml(formatDate(post.date))}${cats ? ` · ${cats}` : ""}`;
      wrap.append(pm);

      groups.append(wrap);

      const hr = document.createElement("hr");
      hr.className = "my-4";
      groups.append(hr);
    }
  }

  const last = groups.lastElementChild;
  if (last && last.tagName.toLowerCase() === "hr") last.remove();
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
        if ((a.getAttribute("target") || "").toLowerCase() === "_blank") return;
        if (a.hasAttribute("download")) return;
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
  const frameWrap = qs("post-frame-wrap");
  const placeholder = qs("post-placeholder");
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
    const isPdf = post.path.toLowerCase().endsWith(".pdf");
    const viewer = isPdf ? pdfViewerUrl(post.path) : post.path;
    const open = `<a class="pill" href="${viewer}" target="_blank" rel="noopener noreferrer">新窗口</a>`;
    const raw = isPdf ? `<a class="pill" href="${post.path}" target="_blank" rel="noopener noreferrer">原始 PDF</a>` : "";
    const download = isPdf ? `<a class="pill" href="${post.path}" download>下载</a>` : "";
    const fullscreen = isPdf ? "" : `<button class="pill pill--btn" type="button" data-action="toggle-fullscreen">全屏</button>`;
    meta.innerHTML =
      `<span class="meta-row">` +
      `<span class="meta-date">${formatDate(post.date)}</span>` +
      `<span class="meta-sep">·</span>` +
      `<span class="meta-cats">${cats}</span>` +
      `</span>` +
      `<span class="meta-actions">${open}${raw}${download}${fullscreen}</span>`;
  }

  const isPdf = isPdfPost(post);
  if (frameWrap) frameWrap.classList.toggle("is-pdf", isPdf);

  if (isPdf) {
    const viewer = pdfViewerUrl(post.path);
    frame.hidden = true;
    frame.removeAttribute("src");
    frame.srcdoc = "";

    if (placeholder) {
      placeholder.hidden = false;
      const key = `pdf.autopen:${post.id}`;
      const opened = (() => {
        try {
          return sessionStorage.getItem(key) === "1";
        } catch {
          return false;
        }
      })();

      let openedNow = false;
      if (!opened) {
        try {
          const w = window.open(viewer, "_blank", "noopener,noreferrer");
          openedNow = Boolean(w);
          sessionStorage.setItem(key, "1");
        } catch {
          // ignore
        }
      }

      placeholder.innerHTML =
        `<div class="post-placeholder__inner">` +
        `<div class="post-placeholder__title">PDF 将在新窗口打开</div>` +
        `<div class="post-placeholder__desc">` +
        (openedNow ? `已为你打开新窗口。` : `如果浏览器拦截了弹窗，请点击下面按钮手动打开。`) +
        `</div>` +
        `<div class="post-placeholder__actions">` +
        `<a class="pill" href="${viewer}" target="_blank" rel="noopener noreferrer">打开 PDF 阅读器</a>` +
        `<a class="pill" href="${post.path}" target="_blank" rel="noopener noreferrer">打开原始 PDF</a>` +
        `<a class="pill" href="${post.path}" download>下载</a>` +
        `</div>` +
        `</div>`;
    }

    return;
  }

  if (placeholder) placeholder.hidden = true;
  frame.hidden = false;
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

function scrollToTopCategory(topName, behavior) {
  const el = document.getElementById(`cat-top_${categoryId(topName)}`);
  if (!el) return;
  try {
    el.scrollIntoView({ behavior: behavior || "smooth", block: "start" });
  } catch {
    el.scrollIntoView(true);
  }
}

function route({ posts, categories }) {
  const hash = parseHashParams();
  let activeCategory = normalizeCategoryPath(hash.c || hash.top || "");

  const isPostPage = Boolean(qs("post-frame"));
  const isCategoryIndex = Boolean(qs("cat-sections"));

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

  if (isCategoryIndex) {
    renderCategoryIndex({ posts, root: categories, activeCategory });
    if (hash.top || (!didInitialRoute && hash.c)) {
      const top = topLevelFromPath(activeCategory);
      if (top) scrollToTopCategory(top, "smooth");
    }
  }

  if (isPostPage) {
    if (postId || postPath) renderPost(posts, { postId, postPath });
  }

  didInitialRoute = true;
}

function setupNav() {
  const btn = document.querySelector("[data-action='nav-toggle']");
  const collapse = document.querySelector("[data-nav-collapse]");
  if (!(btn instanceof HTMLElement) || !(collapse instanceof HTMLElement)) return;

  const close = () => {
    collapse.classList.remove("show");
    btn.setAttribute("aria-expanded", "false");
  };

  btn.addEventListener("click", () => {
    const isOpen = collapse.classList.contains("show");
    if (isOpen) close();
    else {
      collapse.classList.add("show");
      btn.setAttribute("aria-expanded", "true");
    }
  });

  document.addEventListener(
    "click",
    (ev) => {
      if (!collapse.classList.contains("show")) return;
      const target = ev.target;
      if (!(target instanceof Node)) return;
      if (btn.contains(target) || collapse.contains(target)) return;
      close();
    },
    { capture: true },
  );

  window.addEventListener("hashchange", close);
  window.addEventListener("resize", () => {
    if (window.innerWidth >= 992) close();
  });
}

function setupNavScrollChrome() {
  const nav = document.querySelector("[data-nav]");
  if (!(nav instanceof HTMLElement)) return;

  const onScroll = () => {
    nav.classList.toggle("is-scrolled", window.scrollY > 8);
  };

  onScroll();
  window.addEventListener("scroll", onScroll, { passive: true });
}

function setFooterYear() {
  const el = qs("footer-year");
  if (el) el.textContent = String(new Date().getFullYear());
}

async function main() {
  setupNav();
  setupNavScrollChrome();
  setFooterYear();

  const res = await fetch(POSTS_URL, { cache: "no-store" });
  if (!res.ok) throw new Error(`Failed to load ${POSTS_URL}: ${res.status}`);
  const data = await res.json();
  const posts = (data.posts || []).map(normalizePost);
  const categories = buildCategoryTree(posts);

  const frame = qs("post-frame");
  if (frame) decorateIframeLinks(frame, posts);

  document.addEventListener("click", (ev) => {
    const target = ev.target;
    if (!(target instanceof Element)) return;
    const btn = target.closest("[data-action='toggle-fullscreen']");
    if (!btn) return;

    const wrap = qs("post-frame-wrap") || target.closest(".post-frame__wrap");
    if (!wrap) return;

    try {
      if (document.fullscreenElement) document.exitFullscreen();
      else wrap.requestFullscreen();
    } catch {
      // ignore
    }
  });

  route({ posts, categories });
  window.addEventListener("hashchange", () => route({ posts, categories }));
}

main().catch((err) => {
  console.error(err);
  const container = qs("latest-list") || qs("cat-sections") || qs("cat-groups");
  if (container) {
    container.innerHTML =
      `<div style="padding:10px;color:rgba(20,20,20,.7)">` +
      `加载数据失败：<code>${String(err.message || err)}</code><br/>` +
      `请用本地 HTTP 服务预览，或检查 <code>${POSTS_URL}</code> 路径。` +
      `</div>`;
  }
});
