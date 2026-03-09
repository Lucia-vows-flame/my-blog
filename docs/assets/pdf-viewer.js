/* global pdfjsLib */

const WORKER_SRC = new URL("./vendor/pdfjs/pdf.worker.min.js", import.meta.url).toString();

function qs(id) {
  return document.getElementById(id);
}

function disableSidebarPinning() {
  const sidebar = document.querySelector(".pdf-sidebar");
  const sidebarCard = document.querySelector(".pdf-sidebarCard");
  if (sidebar instanceof HTMLElement) {
    sidebar.style.position = "static";
    sidebar.style.top = "auto";
  }
  if (sidebarCard instanceof HTMLElement) {
    sidebarCard.style.position = "static";
    sidebarCard.style.top = "auto";
  }
}

function initKeyboardFocusGating() {
  const root = document.body;
  if (!root) return;

  const onKeyDown = (ev) => {
    // Only enable keyboard focus styles for navigation keys.
    const k = ev.key;
    if (k === "Tab" || k.startsWith("Arrow") || k === "Enter" || k === " ") {
      root.classList.add("kb");
    }
  };
  const onPointer = () => {
    root.classList.remove("kb");
  };

  window.addEventListener("keydown", onKeyDown, { capture: true });
  window.addEventListener("mousedown", onPointer, { capture: true });
  window.addEventListener("touchstart", onPointer, { capture: true, passive: true });
}

function parseHashParams() {
  const raw = (location.hash || "").replace(/^#/, "");
  const params = new URLSearchParams(raw);
  return Object.fromEntries(params.entries());
}

function setHashParams(next) {
  const params = new URLSearchParams(parseHashParams());
  for (const [k, v] of Object.entries(next)) {
    if (v === null || v === undefined || v === "") params.delete(k);
    else params.set(k, String(v));
  }
  const str = params.toString();
  if (`#${str}` !== location.hash) location.hash = str;
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

function getSystemTheme() {
  return window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
}

function normalizeThemePref(pref) {
  const p = String(pref || "system").toLowerCase();
  if (p === "light" || p === "dark" || p === "system") return p;
  return "system";
}

function normalizeMode(mode) {
  const m = String(mode || "scroll").toLowerCase();
  return m === "page" ? "page" : "scroll";
}

function normalizeZoomString(z) {
  const v = String(z || "page-width");
  return v;
}

function formatZoomLabel(z) {
  const zoom = parseZoomValue(z);
  if (zoom === "page-width") return "适合宽度（推荐）";
  if (zoom === "page-fit") return "适合页面（整页）";
  if (typeof zoom === "number") return `${Math.round(zoom * 100)}%`;
  return String(z || "");
}

function formatModeLabel(mode) {
  return normalizeMode(mode) === "page" ? "翻页（单页）" : "滚动（连续）";
}

function formatThemeLabel(pref, actual = pref) {
  const resolved = actual === "dark" ? "暗色" : "亮色";
  return normalizeThemePref(pref) === "system" ? `跟随系统（${resolved}）` : resolved;
}

function setText(el, value) {
  if (el) el.textContent = String(value ?? "");
}

function initDropdown({ rootId, btnId, menuId, initialValue, formatLabel, onChange }) {
  const root = qs(rootId);
  const btn = qs(btnId);
  const menu = qs(menuId);
  if (!root || !btn || !menu) return null;

  const originalParent = menu.parentElement;
  const originalNext = menu.nextSibling;
  let isPortaled = false;
  let raf = 0;

  const opts = [...menu.querySelectorAll("[data-value]")].filter((x) => x instanceof HTMLElement);
  const labelFor = (value) => {
    const v = String(value);
    const match = opts.find((o) => o.dataset.value === v);
    if (match) return match.textContent || v;
    return typeof formatLabel === "function" ? formatLabel(v) : v;
  };

  const setValue = (value) => {
    const v = String(value);
    btn.textContent = labelFor(v);
    for (const o of opts) {
      const selected = o.dataset.value === v;
      o.setAttribute("aria-selected", selected ? "true" : "false");
    }
  };

  const isOpen = () => !menu.hidden;
  const open = () => {
    root.classList.add("is-open");
    menu.hidden = false;
    btn.setAttribute("aria-expanded", "true");
    portal();
    const sel = opts.find((o) => o.getAttribute("aria-selected") === "true") || opts[0];
    sel?.focus?.();
  };
  const close = () => {
    root.classList.remove("is-open");
    unportal();
    menu.hidden = true;
    btn.setAttribute("aria-expanded", "false");
  };
  const toggle = () => {
    if (isOpen()) close();
    else open();
  };

  const reposition = () => {
    if (!isPortaled) return;
    if (raf) cancelAnimationFrame(raf);
    raf = requestAnimationFrame(() => {
      raf = 0;
      const btnRect = btn.getBoundingClientRect();

      // Temporarily measure.
      menu.style.left = "0px";
      menu.style.top = "0px";
      menu.style.maxWidth = "min(360px, 92vw)";
      menu.style.minWidth = `${Math.max(260, Math.floor(btnRect.width))}px`;

      const menuRect = menu.getBoundingClientRect();
      const pad = 10;

      let left = btnRect.right - menuRect.width;
      left = clamp(left, pad, window.innerWidth - menuRect.width - pad);

      let top = btnRect.bottom + 10;
      if (top + menuRect.height > window.innerHeight - pad) {
        top = btnRect.top - 10 - menuRect.height;
        top = Math.max(pad, top);
      }

      menu.style.left = `${Math.round(left)}px`;
      menu.style.top = `${Math.round(top)}px`;
    });
  };

  const portal = () => {
    if (isPortaled) {
      reposition();
      return;
    }
    if (!originalParent) return;

    isPortaled = true;
    menu.dataset.portaled = "1";
    menu.hidden = false;
    menu.style.position = "fixed";
    menu.style.zIndex = "2147483647";
    menu.style.margin = "0";
    menu.style.visibility = "hidden";
    document.body.append(menu);
    reposition();
    menu.style.visibility = "";
  };

  const unportal = () => {
    if (!isPortaled) return;
    isPortaled = false;
    menu.dataset.portaled = "0";
    if (raf) cancelAnimationFrame(raf);
    raf = 0;

    menu.removeAttribute("style");
    if (originalParent) {
      if (originalNext) originalParent.insertBefore(menu, originalNext);
      else originalParent.append(menu);
    }
  };

  btn.addEventListener("click", (ev) => {
    ev.preventDefault();
    toggle();
  });

  btn.addEventListener("keydown", (ev) => {
    if (ev.key === "Enter" || ev.key === " ") {
      ev.preventDefault();
      open();
    } else if (ev.key === "ArrowDown") {
      ev.preventDefault();
      open();
    } else if (ev.key === "Escape") {
      ev.preventDefault();
      close();
    }
  });

  for (const opt of opts) {
    opt.setAttribute("tabindex", "-1");
    opt.addEventListener("click", (ev) => {
      ev.preventDefault();
      const v = opt.dataset.value || "";
      setValue(v);
      onChange?.(v);
      close();
      btn.focus();
    });

    opt.addEventListener("keydown", (ev) => {
      const i = opts.indexOf(opt);
      if (ev.key === "ArrowDown") {
        ev.preventDefault();
        opts[Math.min(opts.length - 1, i + 1)]?.focus?.();
      } else if (ev.key === "ArrowUp") {
        ev.preventDefault();
        opts[Math.max(0, i - 1)]?.focus?.();
      } else if (ev.key === "Enter" || ev.key === " ") {
        ev.preventDefault();
        opt.click();
      } else if (ev.key === "Escape") {
        ev.preventDefault();
        close();
        btn.focus();
      }
    });
  }

  document.addEventListener("mousedown", (ev) => {
    if (!isOpen()) return;
    const t = ev.target;
    if (!(t instanceof Node)) return;
    if (!root.contains(t) && !menu.contains(t)) close();
  });

  window.addEventListener("scroll", () => reposition(), { passive: true });
  window.addEventListener("resize", () => reposition(), { passive: true });

  setValue(initialValue);
  close();
  return { setValue, close, open };
}

function clamp(n, lo, hi) {
  return Math.min(hi, Math.max(lo, n));
}

function basename(path) {
  const s = String(path || "");
  const parts = s.split("/");
  return parts[parts.length - 1] || s;
}

function escapeHtml(s) {
  return String(s)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function escapeAttr(s) {
  return escapeHtml(s).replaceAll("`", "&#96;");
}

function isPdfJsReady() {
  return typeof pdfjsLib !== "undefined" && pdfjsLib?.getDocument;
}

function parseZoomValue(v) {
  if (v === "page-width" || v === "page-fit") return v;
  const n = Number(v);
  if (!Number.isFinite(n)) return "page-width";
  return clamp(n, 0.25, 4);
}

function toUrl(file) {
  try {
    return new URL(file, location.href).toString();
  } catch {
    return String(file || "");
  }
}

function showError(message, { file } = {}) {
  const error = qs("error");
  const loading = qs("loading");
  const viewPage = qs("view-page");
  const viewScroll = qs("view-scroll");
  if (loading) loading.hidden = true;
  if (viewPage) viewPage.hidden = true;
  if (viewScroll) viewScroll.hidden = true;

  if (!error) return;
  error.hidden = false;
  const fileHint = file ? `（文件：<code>${escapeHtml(file)}</code>）` : "";
  const rawLink = file
    ? `<a class="pdf-btn pdf-btn--link" href="${escapeAttr(file)}" target="_blank" rel="noopener noreferrer">打开原始 PDF</a>`
    : "";
  error.innerHTML =
    `<div style="font-weight:700;margin-bottom:6px">PDF 加载失败</div>` +
    `<div style="opacity:.84;line-height:1.6">` +
    `${escapeHtml(message)} ${fileHint}` +
    `</div>` +
    (rawLink ? `<div style="margin-top:12px">${rawLink}</div>` : "");
}

function setLoadingVisible(v, { text } = {}) {
  const loading = qs("loading");
  const loadingText = qs("loading-text");
  if (loadingText && typeof text === "string") loadingText.textContent = text;
  if (loading) loading.hidden = !v;
}

async function resolveDestToPageNumber(pdfDoc, dest) {
  try {
    let destArray = dest;
    if (typeof destArray === "string") destArray = await pdfDoc.getDestination(destArray);
    if (!Array.isArray(destArray) || destArray.length < 1) return null;

    const target = destArray[0];
    if (target && typeof target === "object") {
      const idx = await pdfDoc.getPageIndex(target);
      if (!Number.isFinite(idx)) return null;
      return idx + 1;
    }
    if (Number.isFinite(target)) {
      const n = Math.trunc(target);
      if (n >= 0 && n < pdfDoc.numPages) return n + 1;
      if (n >= 1 && n <= pdfDoc.numPages) return n;
    }
    return null;
  } catch {
    return null;
  }
}

async function renderLinkAnnotations({ pdfDoc, page, viewport, layerEl, onGoToPage, onNamedAction }) {
  layerEl.innerHTML = "";
  layerEl.style.width = `${Math.ceil(viewport.width)}px`;
  layerEl.style.height = `${Math.ceil(viewport.height)}px`;

  const annotations = await page.getAnnotations({ intent: "display" });
  for (const a of annotations || []) {
    if ((a.subtype || "").toLowerCase() !== "link") continue;
    const rect = a.rect;
    if (!Array.isArray(rect) || rect.length !== 4) continue;

    const r = viewport.convertToViewportRectangle(rect);
    const left = Math.min(r[0], r[2]);
    const top = Math.min(r[1], r[3]);
    const width = Math.abs(r[0] - r[2]);
    const height = Math.abs(r[1] - r[3]);
    if (!(width > 0 && height > 0)) continue;

    const link = document.createElement("a");
    link.className = "pdf-link";
    link.style.left = `${left}px`;
    link.style.top = `${top}px`;
    link.style.width = `${width}px`;
    link.style.height = `${height}px`;

    const url = a.url || a.unsafeUrl || "";
    if (url) {
      link.href = url;
      link.target = "_blank";
      link.rel = "noopener noreferrer";
      link.title = url;
      layerEl.append(link);
      continue;
    }

    if (a.dest) {
      const pageNum = await resolveDestToPageNumber(pdfDoc, a.dest);
      if (pageNum) {
        link.href = "#";
        link.dataset.goPage = String(pageNum);
        link.title = `跳转到第 ${pageNum} 页`;
        link.addEventListener("click", (ev) => {
          ev.preventDefault();
          onGoToPage(pageNum);
        });
        layerEl.append(link);
        continue;
      }
    }

    const action = String(a.action || "");
    if (action) {
      link.href = "#";
      link.title = action;
      link.addEventListener("click", (ev) => {
        ev.preventDefault();
        onNamedAction?.(action);
      });
      layerEl.append(link);
      continue;
    }

    // Fallback: do nothing but keep clickable highlight.
    link.href = "#";
    link.addEventListener("click", (ev) => ev.preventDefault());
    layerEl.append(link);
  }
}

function computeScale({ zoom, viewportAtScale1, containerEl }) {
  if (typeof zoom === "number") return zoom;

  const pad = 32;
  const rect = typeof containerEl?.getBoundingClientRect === "function" ? containerEl.getBoundingClientRect() : null;
  const width = Math.max(containerEl?.clientWidth || 0, Math.round(rect?.width || 0));
  const viewportHeight = Math.max(220, window.innerHeight - Math.max(24, Math.round(rect?.top || 0)) - 24);
  const height = Math.max(containerEl?.clientHeight || 0, Math.round(rect?.height || 0));
  const cw = Math.max(200, width - pad);
  const ch = Math.max(200, Math.min(Math.max(220, height - pad), viewportHeight));

  if (zoom === "page-fit") {
    const sx = cw / viewportAtScale1.width;
    const sy = ch / viewportAtScale1.height;
    return clamp(Math.min(sx, sy), 0.25, 4);
  }
  return clamp(cw / viewportAtScale1.width, 0.25, 4);
}

function formatMode(mode) {
  return mode === "page" ? "page" : "scroll";
}

function prepareCanvasForViewport({ canvas, ctx, viewport, outputScale }) {
  const cssWidth = Math.ceil(viewport.width);
  const cssHeight = Math.ceil(viewport.height);
  canvas.width = Math.ceil(cssWidth * outputScale);
  canvas.height = Math.ceil(cssHeight * outputScale);
  canvas.style.width = `${cssWidth}px`;
  canvas.style.height = `${cssHeight}px`;

  // Ensure the backing store is fully painted even if the PDF page doesn't draw a background.
  // (Important when the 2D context is created with `{ alpha: false }`.)
  ctx.setTransform(1, 0, 0, 1, 0, 0);
  ctx.fillStyle = "#fff";
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  return { cssWidth, cssHeight };
}

async function renderPageToCanvas({ page, viewport, canvas, ctx, outputScale }) {
  const sizes = prepareCanvasForViewport({ canvas, ctx, viewport, outputScale });

  const transform = outputScale === 1 ? undefined : [outputScale, 0, 0, outputScale, 0, 0];
  await page.render({ canvasContext: ctx, viewport, transform }).promise;
  return sizes;
}

async function main() {
  initKeyboardFocusGating();

  const params = parseHashParams();
  const file = params.file || "";
  if (!file) {
    showError("缺少参数：file", {});
    return;
  }

  const themePrefInit = normalizeThemePref(params.theme || safeLocalStorageGet("pdf.theme") || "system");
  let themePref = themePrefInit;
  let state = null;
  let stateReady = false;
  /** @type {{setValue:(v:string)=>void, close:()=>void, open:()=>void} | null} */
  let themeDd = null;
  /** @type {{setValue:(v:string)=>void, close:()=>void, open:()=>void} | null} */
  let modeDd = null;
  /** @type {{setValue:(v:string)=>void, close:()=>void, open:()=>void} | null} */
  let zoomDd = null;

  const applyTheme = (pref) => {
    themePref = normalizeThemePref(pref);
    safeLocalStorageSet("pdf.theme", themePref);
    themeDd?.setValue(themePref);
    const actual = themePref === "system" ? getSystemTheme() : themePref;
    document.body.dataset.theme = actual;
    document.body.dataset.themePref = themePref;
    if (stateReady) updateSummary();
  };

  applyTheme(themePrefInit);

  const mm = window.matchMedia ? window.matchMedia("(prefers-color-scheme: dark)") : null;
  const onSystemThemeChange = () => {
    if (themePref !== "system") return;
    applyTheme("system");
  };
  try {
    mm?.addEventListener?.("change", onSystemThemeChange);
  } catch {
    // ignore
  }

  const initialMode = formatMode(params.mode || safeLocalStorageGet("pdf.mode") || "scroll");
  const initialZoomRaw = normalizeZoomString(params.zoom || safeLocalStorageGet("pdf.zoom") || "page-width");
  const initialZoom = parseZoomValue(initialZoomRaw);
  const initialRotate = Number(params.rotate || safeLocalStorageGet("pdf.rotate") || "0");
  const initialPage = Number(params.page || "1");

  const title = qs("pdf-title");
  const subtitle = qs("pdf-subtitle");
  const fileBaseName = basename(file);
  if (title) title.textContent = fileBaseName;
  if (subtitle) subtitle.textContent = file;

  const openRaw = qs("open-raw");
  const download = qs("download");
  if (openRaw) openRaw.setAttribute("href", file);
  if (download) download.setAttribute("href", file);

  setLoadingVisible(true, { text: `正在加载：${basename(file)}` });

  if (!isPdfJsReady()) {
    showError("PDF.js 未加载（可能是网络受限或 CDN 不可用）。", { file });
    return;
  }

  pdfjsLib.GlobalWorkerOptions.workerSrc = WORKER_SRC;

  const viewPage = qs("view-page");
  const viewScroll = qs("view-scroll");
  const canvas = qs("pdf-canvas");
  const annoLayer = qs("anno-layer");
  const pagesEl = qs("pages");
  const pageNumber = qs("page-number");
  const pageCount = qs("page-count");
  const prevPage = qs("prev-page");
  const nextPage = qs("next-page");
  const zoomIn = qs("zoom-in");
  const zoomOut = qs("zoom-out");
  const rotateBtn = qs("rotate");
  const stage = qs("stage");
  const statusPage = qs("pdf-status-page");
  const statusTotal = qs("pdf-status-total");
  const statusProgress = qs("pdf-status-progress");
  const progressPercent = qs("pdf-progress-percent");
  const progressBar = qs("pdf-progress-bar");
  const progressText = qs("pdf-progress-text");
  const progressMode = qs("pdf-progress-mode");
  const outlineRoot = qs("pdf-outline");
  const outlineEmpty = qs("pdf-outline-empty");
  const outlineScroller = qs("pdf-outline-scroller");
  const fileNamePrimary = qs("pdf-file-name");
  const infoName = qs("pdf-info-name");
  const infoPages = qs("pdf-info-pages");
  const infoMode = qs("pdf-info-mode");
  const infoTheme = qs("pdf-info-theme");
  const infoZoom = qs("pdf-info-zoom");
  const metaMode = qs("pdf-meta-mode");
  const metaTheme = qs("pdf-meta-theme");
  const metaZoom = qs("pdf-meta-zoom");
  const metaPages = qs("pdf-meta-pages");

  disableSidebarPinning();
  document.body.classList.remove("pdf-reader-expanded");

  if (!viewPage || !viewScroll || !canvas || !annoLayer || !pagesEl || !stage) {
    showError("Viewer DOM 不完整。", { file });
    return;
  }

  setText(fileNamePrimary, fileBaseName);
  setText(infoName, fileBaseName);

  const ctx = canvas.getContext("2d", { alpha: false });
  if (!ctx) {
    showError("Canvas context 创建失败。", { file });
    return;
  }

  /** @type {{pdfDoc:any, mode:'scroll'|'page', pageNum:number, zoom:any, rotate:number, rendering:boolean, pending:boolean}} */
  state = {
    pdfDoc: null,
    mode: initialMode,
    pageNum: Number.isFinite(initialPage) ? clamp(Math.trunc(initialPage), 1, 999999) : 1,
    zoom: initialZoom,
    rotate: Number.isFinite(initialRotate) ? Math.trunc(initialRotate) % 360 : 0,
    rendering: false,
    pending: false,
  };

  const fileUrl = toUrl(file);
  let loadingTask;
  try {
    loadingTask = pdfjsLib.getDocument({ url: fileUrl });
    state.pdfDoc = await loadingTask.promise;
  } catch (err) {
    showError(String(err?.message || err || "unknown error"), { file });
    return;
  }

  if (pageCount) pageCount.textContent = String(state.pdfDoc.numPages || "?");
  state.pageNum = clamp(state.pageNum, 1, state.pdfDoc.numPages || 1);
  if (pageNumber) pageNumber.value = String(state.pageNum);
  stateReady = true;

  /** @type {Map<number, {el:HTMLElement, canvas:HTMLCanvasElement, ctx:CanvasRenderingContext2D, anno:HTMLElement, renderedKey:string|null}>} */
  const pageNodes = new Map();
  /** @type {IntersectionObserver|null} */
  let renderObserver = null;
  /** @type {IntersectionObserver|null} */
  let activeObserver = null;
  /** @type {Map<string, {wrapper:HTMLElement, button:HTMLButtonElement, parentId:string|null, page:number|null}>} */
  const outlineMap = new Map();
  /** @type {{id:string,parentId:string|null,title:string,page:number|null,url:string,action:string,depth:number,children:any[]}[]} */
  let outlineLinear = [];
  let activeOutlineId = "";

  function flattenOutline(items, target = []) {
    for (const item of items) {
      target.push(item);
      if (item.children?.length) flattenOutline(item.children, target);
    }
    return target;
  }

  async function buildOutlineItems(items, parentId = null, depth = 0, path = []) {
    const nodes = [];
    for (let i = 0; i < (items || []).length; i += 1) {
      const item = items[i];
      const id = `outline-${[...path, i].join("-")}`;
      const page = item?.dest ? await resolveDestToPageNumber(state.pdfDoc, item.dest) : null;
      const children = item?.items?.length ? await buildOutlineItems(item.items, id, depth + 1, [...path, i]) : [];
      nodes.push({
        id,
        parentId,
        depth,
        title: String(item?.title || "未命名章节").trim() || "未命名章节",
        page,
        url: String(item?.url || item?.unsafeUrl || ""),
        action: String(item?.action || ""),
        children,
      });
    }
    return nodes;
  }

  function setOutlineExpanded(id, expanded) {
    const entry = outlineMap.get(id);
    if (!entry) return;
    entry.wrapper.classList.toggle("is-expanded", expanded);
  }

  function ensureOutlineAncestorsExpanded(id) {
    let currentId = id;
    while (currentId) {
      const entry = outlineMap.get(currentId);
      if (!entry) break;
      entry.wrapper.classList.add("is-expanded");
      currentId = entry.parentId || "";
    }
  }

  function pickActiveOutlineId(pageNum) {
    let match = "";
    let first = "";
    for (const item of outlineLinear) {
      if (!Number.isFinite(item.page) || item.page < 1) continue;
      if (!first) first = item.id;
      if (item.page <= pageNum) match = item.id;
    }
    return match || first;
  }

  function updateOutlineActive({ scroll = true } = {}) {
    if (!outlineLinear.length) return;
    const nextId = pickActiveOutlineId(state.pageNum);
    if (!nextId && !activeOutlineId) return;

    for (const [id, entry] of outlineMap.entries()) {
      entry.button.classList.toggle("is-active", id === nextId);
    }

    if (nextId) {
      ensureOutlineAncestorsExpanded(nextId);
      if (scroll && nextId !== activeOutlineId && outlineScroller?.offsetParent !== null) {
        const entry = outlineMap.get(nextId);
        entry?.button?.scrollIntoView?.({ block: "nearest", inline: "nearest" });
      }
    }

    activeOutlineId = nextId;
  }

  function renderOutlineNode(item) {
    const wrapper = document.createElement("div");
    wrapper.className = "pdf-tocNode";
    wrapper.dataset.id = item.id;
    if (item.depth <= 0) wrapper.classList.add("is-expanded");

    const row = document.createElement("div");
    row.className = "pdf-tocRow";

    const toggle = document.createElement("button");
    toggle.className = "pdf-tocToggle";
    toggle.type = "button";
    toggle.setAttribute("aria-label", item.children.length ? `展开或折叠 ${item.title}` : `${item.title}`);
    toggle.disabled = !item.children.length;
    toggle.addEventListener("click", (ev) => {
      ev.preventDefault();
      ev.stopPropagation();
      if (!item.children.length) return;
      const expanded = !wrapper.classList.contains("is-expanded");
      setOutlineExpanded(item.id, expanded);
    });

    const button = document.createElement("button");
    button.className = "pdf-tocButton";
    button.type = "button";
    button.style.setProperty("--depth", String(item.depth));
    button.setAttribute("role", "treeitem");
    button.setAttribute("aria-label", item.page ? `${item.title}，第 ${item.page} 页` : item.title);
    button.innerHTML =
      `<span class="pdf-tocLabel">${escapeHtml(item.title)}</span>` +
      (item.page ? `<span class="pdf-tocPage">P. ${item.page}</span>` : "");
    button.addEventListener("click", (ev) => {
      ev.preventDefault();
      if (Number.isFinite(item.page) && item.page) {
        goToPage(item.page);
        return;
      }
      if (item.url) {
        window.open(item.url, "_blank", "noopener,noreferrer");
        return;
      }
      if (item.action) {
        goToNamedAction(item.action);
        return;
      }
      if (item.children.length) {
        const expanded = !wrapper.classList.contains("is-expanded");
        setOutlineExpanded(item.id, expanded);
      }
    });

    row.append(toggle, button);
    wrapper.append(row);

    outlineMap.set(item.id, { wrapper, button, parentId: item.parentId, page: item.page });

    if (item.children.length) {
      const childrenEl = document.createElement("div");
      childrenEl.className = "pdf-tocChildren";
      childrenEl.setAttribute("role", "group");
      for (const child of item.children) {
        childrenEl.append(renderOutlineNode(child));
      }
      wrapper.append(childrenEl);
    }

    return wrapper;
  }

  function renderOutline(items) {
    if (!outlineRoot || !outlineEmpty) return;
    outlineMap.clear();
    outlineLinear = flattenOutline(items, []);
    activeOutlineId = "";
    outlineRoot.innerHTML = "";

    if (!outlineLinear.length) {
      outlineRoot.hidden = true;
      outlineEmpty.hidden = false;
      return;
    }

    outlineRoot.hidden = false;
    outlineEmpty.hidden = true;
    const frag = document.createDocumentFragment();
    for (const item of items) frag.append(renderOutlineNode(item));
    outlineRoot.append(frag);
    updateOutlineActive({ scroll: false });
  }

  async function loadOutline() {
    if (!outlineRoot || !outlineEmpty) return;
    try {
      const outline = await state.pdfDoc.getOutline();
      const items = outline?.length ? await buildOutlineItems(outline) : [];
      renderOutline(items);
    } catch {
      renderOutline([]);
    }
  }

  function updateSummary() {
    if (!stateReady || !state) return;

    const total = state.pdfDoc?.numPages || 0;
    const maxPage = Math.max(1, total || 1);
    const page = clamp(state.pageNum || 1, 1, maxPage);
    const progress = total ? Math.round((page / maxPage) * 100) : 0;
    const modeLabel = formatModeLabel(state.mode);
    const actualTheme = document.body.dataset.theme || getSystemTheme();
    const themeLabel = formatThemeLabel(themePref, actualTheme);
    const zoomValue = typeof state.zoom === "number" ? String(state.zoom) : String(state.zoom);
    const zoomLabel = formatZoomLabel(zoomValue);
    const pageLabel = total ? `${page} / ${total}` : `${page} / ?`;

    setText(statusPage, page);
    setText(statusTotal, total || "?");
    setText(statusProgress, `${progress}%`);
    setText(progressPercent, `${progress}%`);
    setText(progressText, total ? `第 ${page} 页，共 ${total} 页` : `第 ${page} 页`);
    setText(progressMode, modeLabel);
    setText(infoPages, total || "?");
    setText(infoMode, modeLabel);
    setText(infoTheme, themeLabel);
    setText(infoZoom, zoomLabel);
    setText(metaMode, modeLabel);
    setText(metaTheme, themeLabel);
    setText(metaZoom, zoomLabel);
    setText(metaPages, pageLabel);
    if (progressBar) progressBar.style.width = `${progress}%`;
    if (subtitle) subtitle.textContent = total ? `${file} · ${page}/${total}` : file;
    document.title = total ? `${fileBaseName} · ${page}/${total}` : fileBaseName;
    updateOutlineActive();
  }

  function updateNav() {
    if (prevPage) prevPage.disabled = state.pageNum <= 1;
    if (nextPage) nextPage.disabled = state.pageNum >= (state.pdfDoc?.numPages || 1);
    if (pageNumber) pageNumber.value = String(state.pageNum);
    updateSummary();
  }

  function setMode(mode) {
    state.mode = formatMode(mode);
    safeLocalStorageSet("pdf.mode", state.mode);
    modeDd?.setValue(state.mode);
    updateSummary();
  }

  function setZoom(next) {
    state.zoom = parseZoomValue(next);
    safeLocalStorageSet("pdf.zoom", typeof state.zoom === "number" ? String(state.zoom) : state.zoom);
    zoomDd?.setValue(typeof state.zoom === "number" ? String(state.zoom) : String(state.zoom));
    updateSummary();
  }

  function zoomBy(delta) {
    const current = typeof state.zoom === "number" ? state.zoom : 1;
    const next = clamp(Math.round((current + delta) * 100) / 100, 0.25, 4);
    setZoom(next);
  }

  function setRotate(next) {
    state.rotate = ((Math.trunc(next) % 360) + 360) % 360;
    safeLocalStorageSet("pdf.rotate", String(state.rotate));
  }

  function syncHash() {
    setHashParams({
      file,
      theme: themePref,
      mode: state.mode,
      page: state.pageNum,
      zoom: typeof state.zoom === "number" ? String(state.zoom) : state.zoom,
      rotate: state.rotate ? String(state.rotate) : null,
    });
  }

  function showViews() {
    const isPage = state.mode === "page";
    document.body.dataset.mode = state.mode;
    viewPage.hidden = !isPage;
    viewScroll.hidden = isPage;
  }

  async function renderSinglePage() {
    if (state.rendering) {
      state.pending = true;
      return;
    }
    state.rendering = true;
    state.pending = false;
    setLoadingVisible(true, { text: `正在渲染：${state.pageNum}/${state.pdfDoc.numPages}` });

    try {
      const page = await state.pdfDoc.getPage(state.pageNum);
      const viewport1 = page.getViewport({ scale: 1, rotation: state.rotate });
      const scale = computeScale({ zoom: state.zoom, viewportAtScale1: viewport1, containerEl: stage });
      const viewport = page.getViewport({ scale, rotation: state.rotate });

      const outputScale = window.devicePixelRatio || 1;

      ctx.imageSmoothingEnabled = true;
      ctx.imageSmoothingQuality = "high";
      const { cssWidth, cssHeight } = await renderPageToCanvas({ page, viewport, canvas, ctx, outputScale });

      annoLayer.style.width = `${cssWidth}px`;
      annoLayer.style.height = `${cssHeight}px`;

      await renderLinkAnnotations({
        pdfDoc: state.pdfDoc,
        page,
        viewport,
        layerEl: annoLayer,
        onGoToPage: (n) => goToPage(n),
        onNamedAction: (action) => goToNamedAction(action),
      });

      updateSummary();
    } finally {
      setLoadingVisible(false);
      state.rendering = false;
      updateNav();
      syncHash();
      if (state.pending) queueMicrotask(renderSinglePage);
    }
  }

  function ensureScrollPagesBuilt() {
    if (pageNodes.size) return;
    pagesEl.innerHTML = "";

    for (let i = 1; i <= state.pdfDoc.numPages; i += 1) {
      const item = document.createElement("div");
      item.className = "pdf-pageItem";
      item.dataset.page = String(i);

      const layer = document.createElement("div");
      layer.className = "pdf-pageLayer";

      const c = document.createElement("canvas");
      c.className = "pdf-canvas";

      const anno = document.createElement("div");
      anno.className = "pdf-annoLayer";
      anno.setAttribute("aria-hidden", "true");

      layer.append(c, anno);
      item.append(layer);
      pagesEl.append(item);

      const cctx = c.getContext("2d", { alpha: false });
      if (!cctx) continue;
      pageNodes.set(i, { el: item, canvas: c, ctx: cctx, anno, renderedKey: null });
    }
  }

  function invalidateScrollRenders() {
    for (const node of pageNodes.values()) node.renderedKey = null;
  }

  let layoutRefreshToken = 0;
  let readerDocked = window.innerWidth > 1100;

  function usesDockedReaderLayout() {
    return window.innerWidth > 1100;
  }

  function getScrollViewport() {
    if (state.mode !== "scroll" || !usesDockedReaderLayout()) return null;
    return stage instanceof HTMLElement ? stage : null;
  }

  function getAnchorOffset(node, rootEl) {
    const rect = node?.getBoundingClientRect?.();
    if (!rect) return 0;
    if (!(rootEl instanceof HTMLElement)) return rect.top;
    const rootRect = rootEl.getBoundingClientRect();
    return rect.top - rootRect.top + rootEl.scrollTop;
  }

  function isNodeNearViewport(nodeEl, rootEl) {
    const rect = nodeEl.getBoundingClientRect();
    if (!(rootEl instanceof HTMLElement)) {
      return !(rect.bottom < -window.innerHeight || rect.top > window.innerHeight * 2);
    }
    const rootRect = rootEl.getBoundingClientRect();
    const margin = Math.max(280, rootEl.clientHeight);
    return !(rect.bottom < rootRect.top - margin || rect.top > rootRect.bottom + margin);
  }

  async function refreshLayoutRendering() {
    if (!stateReady || !state?.pdfDoc) return;
    const rootEl = getScrollViewport();
    if (state.mode === "page") {
      if (state.zoom === "page-width" || state.zoom === "page-fit") renderSinglePage();
      return;
    }
    if (typeof state.zoom === "number") return;

    const anchorPage = state.pageNum;
    const anchorNode = pageNodes.get(anchorPage)?.el || null;
    const anchorOffsetBefore = anchorNode ? getAnchorOffset(anchorNode, rootEl) : 0;
    const token = ++layoutRefreshToken;

    invalidateScrollRenders();

    const tasks = [];
    for (const [pageNum, node] of pageNodes.entries()) {
      if (!isNodeNearViewport(node.el, rootEl)) continue;
      tasks.push(renderScrollPage(pageNum).catch(() => {}));
    }
    await Promise.all(tasks);
    if (token !== layoutRefreshToken) return;

    const anchorOffsetAfter = pageNodes.get(anchorPage)?.el ? getAnchorOffset(pageNodes.get(anchorPage).el, rootEl) : 0;
    const delta = anchorOffsetAfter - anchorOffsetBefore;
    if (Math.abs(delta) > 1) {
      if (rootEl instanceof HTMLElement) rootEl.scrollTop += delta;
      else window.scrollBy({ top: delta, behavior: "auto" });
    }
    setupObservers();
    updateNav();
  }

  async function renderScrollPage(pageNum) {
    const node = pageNodes.get(pageNum);
    if (!node) return;

    const key = `${state.rotate}:${typeof state.zoom === "number" ? state.zoom : state.zoom}:${node.el.clientWidth}`;
    if (node.renderedKey === key) return;
    node.renderedKey = key;

    const page = await state.pdfDoc.getPage(pageNum);
    const viewport1 = page.getViewport({ scale: 1, rotation: state.rotate });
    const scale = computeScale({ zoom: state.zoom, viewportAtScale1: viewport1, containerEl: stage });
    const viewport = page.getViewport({ scale, rotation: state.rotate });

    const outputScale = window.devicePixelRatio || 1;

    node.ctx.imageSmoothingEnabled = true;
    node.ctx.imageSmoothingQuality = "high";
    const { cssWidth, cssHeight } = await renderPageToCanvas({
      page,
      viewport,
      canvas: node.canvas,
      ctx: node.ctx,
      outputScale,
    });

    node.anno.style.width = `${cssWidth}px`;
    node.anno.style.height = `${cssHeight}px`;

    await renderLinkAnnotations({
      pdfDoc: state.pdfDoc,
      page,
      viewport,
      layerEl: node.anno,
      onGoToPage: (n) => goToPage(n),
      onNamedAction: (action) => goToNamedAction(action),
    });
  }

  function scrollPageNodeIntoView(pageNum, behavior = "smooth") {
    const node = pageNodes.get(pageNum);
    const pageEl = node?.el;
    if (!(pageEl instanceof HTMLElement)) return;

    const rootEl = getScrollViewport();
    if (!(rootEl instanceof HTMLElement)) {
      pageEl.scrollIntoView({ behavior, block: "start" });
      return;
    }

    const rootRect = rootEl.getBoundingClientRect();
    const pageRect = pageEl.getBoundingClientRect();
    const nextTop = rootEl.scrollTop + (pageRect.top - rootRect.top) - 18;
    rootEl.scrollTo({ top: Math.max(0, nextTop), behavior });
  }

  function setupObservers() {
    if (renderObserver) renderObserver.disconnect();
    if (activeObserver) activeObserver.disconnect();

    const observerRoot = getScrollViewport();
    const renderRootMargin = observerRoot instanceof HTMLElement
      ? `${Math.round(Math.max(360, observerRoot.clientHeight * 0.9))}px 0px`
      : "800px 0px";
    const activeRootMargin = observerRoot instanceof HTMLElement
      ? "-10% 0px -62% 0px"
      : "-45% 0px -50% 0px";

    renderObserver = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (!e.isIntersecting) continue;
          const el = /** @type {HTMLElement} */ (e.target);
          const p = Number(el.dataset.page || "0");
          if (!Number.isFinite(p) || p < 1) continue;
          renderScrollPage(p).catch(() => {
            // ignore render errors per-page
          });
        }
      },
      { root: observerRoot, rootMargin: renderRootMargin, threshold: 0.01 },
    );

    activeObserver = new IntersectionObserver(
      (entries) => {
        let best = null;
        for (const e of entries) {
          if (!e.isIntersecting) continue;
          const el = /** @type {HTMLElement} */ (e.target);
          const p = Number(el.dataset.page || "0");
          if (!Number.isFinite(p) || p < 1) continue;
          const score = e.intersectionRatio;
          if (!best || score > best.score) best = { page: p, score };
        }
        if (best && best.page !== state.pageNum) {
          state.pageNum = best.page;
          updateNav();
          syncHash();
        }
      },
      { root: observerRoot, rootMargin: activeRootMargin, threshold: [0.05, 0.1, 0.2, 0.35, 0.5, 0.7] },
    );

    for (const node of pageNodes.values()) {
      renderObserver.observe(node.el);
      activeObserver.observe(node.el);
    }
  }

  function goToPage(n) {
    const pageNum = clamp(Math.trunc(n), 1, state.pdfDoc.numPages);
    state.pageNum = pageNum;
    updateNav();
    if (state.mode === "page") {
      renderSinglePage();
      return;
    }
    scrollPageNodeIntoView(pageNum, "smooth");
    syncHash();
  }

  function goToNamedAction(action) {
    if (action === "NextPage") goToPage(state.pageNum + 1);
    else if (action === "PrevPage") goToPage(state.pageNum - 1);
    else if (action === "FirstPage") goToPage(1);
    else if (action === "LastPage") goToPage(state.pdfDoc.numPages);
  }

  function applyModeAndRender() {
    showViews();
    updateNav();
    syncHash();

    if (state.mode === "page") {
      renderObserver?.disconnect();
      activeObserver?.disconnect();
      setLoadingVisible(false);
      renderSinglePage();
      return;
    }

    ensureScrollPagesBuilt();
    setupObservers();
    setLoadingVisible(false);
    // Scroll to the current page after DOM ready.
    queueMicrotask(() => {
      scrollPageNodeIntoView(state.pageNum, "auto");
    });
  }

  await loadOutline();

  modeDd = initDropdown({
    rootId: "dd-mode",
    btnId: "mode-btn",
    menuId: "mode-menu",
    initialValue: state.mode,
    onChange: (v) => {
      setMode(v);
      applyModeAndRender();
    },
  });

  themeDd = initDropdown({
    rootId: "dd-theme",
    btnId: "theme-btn",
    menuId: "theme-menu",
    initialValue: themePref,
    onChange: (v) => {
      applyTheme(v);
      syncHash();
    },
  });

  zoomDd = initDropdown({
    rootId: "dd-zoom",
    btnId: "zoom-btn",
    menuId: "zoom-menu",
    initialValue: typeof state.zoom === "number" ? String(state.zoom) : initialZoomRaw,
    formatLabel: (v) => formatZoomLabel(v),
    onChange: (v) => {
      setZoom(v);
      if (state.mode === "scroll") invalidateScrollRenders();
      applyModeAndRender();
    },
  });

  // Ensure theme is applied after dropdown is ready (so button label updates).
  applyTheme(themePref);
  updateSummary();

  prevPage?.addEventListener("click", () => goToPage(state.pageNum - 1));
  nextPage?.addEventListener("click", () => goToPage(state.pageNum + 1));

  pageNumber?.addEventListener("keydown", (ev) => {
    if (ev.key !== "Enter") return;
    const v = Number(pageNumber.value || "1");
    if (!Number.isFinite(v)) return;
    goToPage(v);
  });

  zoomIn?.addEventListener("click", () => {
    zoomBy(0.1);
    if (state.mode === "scroll") invalidateScrollRenders();
    applyModeAndRender();
  });
  zoomOut?.addEventListener("click", () => {
    zoomBy(-0.1);
    if (state.mode === "scroll") invalidateScrollRenders();
    applyModeAndRender();
  });
  rotateBtn?.addEventListener("click", () => {
    setRotate(state.rotate + 90);
    if (state.mode === "scroll") invalidateScrollRenders();
    applyModeAndRender();
  });

  window.addEventListener("resize", () => {
    const nextDocked = usesDockedReaderLayout();
    const dockChanged = nextDocked !== readerDocked;
    readerDocked = nextDocked;

    if (state.mode === "page") {
      if (state.zoom === "page-width" || state.zoom === "page-fit") renderSinglePage();
      return;
    }

    if (dockChanged) {
      setupObservers();
      queueMicrotask(() => {
        scrollPageNodeIntoView(state.pageNum, "auto");
      });
    }

    if (state.zoom === "page-width" || state.zoom === "page-fit") {
      invalidateScrollRenders();
      applyModeAndRender();
      return;
    }

    updateNav();
  });

  window.addEventListener("keydown", (ev) => {
    if (ev.altKey || ev.ctrlKey || ev.metaKey) return;
    if (ev.key === "ArrowLeft") {
      ev.preventDefault();
      goToPage(state.pageNum - 1);
    } else if (ev.key === "ArrowRight") {
      ev.preventDefault();
      goToPage(state.pageNum + 1);
    } else if (ev.key === "+" || ev.key === "=") {
      ev.preventDefault();
      zoomBy(0.1);
      if (state.mode === "scroll") invalidateScrollRenders();
      applyModeAndRender();
    } else if (ev.key === "-" || ev.key === "_") {
      ev.preventDefault();
      zoomBy(-0.1);
      if (state.mode === "scroll") invalidateScrollRenders();
      applyModeAndRender();
    } else if (ev.key.toLowerCase() === "r") {
      ev.preventDefault();
      setRotate(state.rotate + 90);
      if (state.mode === "scroll") invalidateScrollRenders();
      applyModeAndRender();
    }
  });

  window.addEventListener("hashchange", () => {
    const p = parseHashParams();
    if (p.file && p.file !== file) return;

    const nextThemePref = normalizeThemePref(p.theme || themePref);
    if (nextThemePref !== themePref) {
      applyTheme(nextThemePref);
    }

    const nextMode = formatMode(p.mode || state.mode);
    const nextZoom = parseZoomValue(p.zoom || state.zoom);
    const nextRotate = Number(p.rotate || state.rotate);
    const nextPage = Number(p.page || state.pageNum);

    let changed = false;
    if (nextMode !== state.mode) {
      setMode(nextMode);
      changed = true;
    }
    if (String(nextZoom) !== String(state.zoom)) {
      setZoom(nextZoom);
      changed = true;
    }
    if (Number.isFinite(nextRotate) && (Math.trunc(nextRotate) % 360) !== state.rotate) {
      setRotate(nextRotate);
      changed = true;
    }
    if (Number.isFinite(nextPage) && clamp(Math.trunc(nextPage), 1, state.pdfDoc.numPages) !== state.pageNum) {
      state.pageNum = clamp(Math.trunc(nextPage), 1, state.pdfDoc.numPages);
      changed = true;
    }

    if (changed) {
      if (state.mode === "scroll") invalidateScrollRenders();
      applyModeAndRender();
    } else {
      updateNav();
    }
  });

  setLoadingVisible(false);
  applyModeAndRender();
}

main().catch((err) => {
  const params = parseHashParams();
  showError(String(err?.message || err || "unknown error"), { file: params.file || "" });
});
