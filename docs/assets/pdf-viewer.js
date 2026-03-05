/* global pdfjsLib */

const PDFJS_VERSION = "3.11.174";
const WORKER_SRC = `https://cdnjs.cloudflare.com/ajax/libs/pdf.js/${PDFJS_VERSION}/pdf.worker.min.js`;

function qs(id) {
  return document.getElementById(id);
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
    `<div style="color:rgba(255,255,255,.72);line-height:1.6">` +
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
  layerEl.style.width = `${Math.floor(viewport.width)}px`;
  layerEl.style.height = `${Math.floor(viewport.height)}px`;

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
  const cw = Math.max(200, containerEl.clientWidth - pad);
  const ch = Math.max(200, containerEl.clientHeight - pad);
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

async function main() {
  const params = parseHashParams();
  const file = params.file || "";
  if (!file) {
    showError("缺少参数：file", {});
    return;
  }

  const initialMode = formatMode(params.mode || safeLocalStorageGet("pdf.mode") || "scroll");
  const initialZoom = parseZoomValue(params.zoom || safeLocalStorageGet("pdf.zoom") || "page-width");
  const initialRotate = Number(params.rotate || safeLocalStorageGet("pdf.rotate") || "0");
  const initialPage = Number(params.page || "1");

  const title = qs("pdf-title");
  const subtitle = qs("pdf-subtitle");
  if (title) title.textContent = basename(file);
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
  const zoomSelect = qs("zoom-select");
  const zoomIn = qs("zoom-in");
  const zoomOut = qs("zoom-out");
  const rotateBtn = qs("rotate");
  const modeSelect = qs("mode-select");
  const stage = qs("stage");

  if (!viewPage || !viewScroll || !canvas || !annoLayer || !pagesEl || !stage) {
    showError("Viewer DOM 不完整。", { file });
    return;
  }

  if (modeSelect) modeSelect.value = initialMode;
  if (zoomSelect) zoomSelect.value = String(initialZoom);

  const ctx = canvas.getContext("2d", { alpha: false });
  if (!ctx) {
    showError("Canvas context 创建失败。", { file });
    return;
  }

  /** @type {{pdfDoc:any, mode:'scroll'|'page', pageNum:number, zoom:any, rotate:number, rendering:boolean, pending:boolean}} */
  const state = {
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

  /** @type {Map<number, {el:HTMLElement, canvas:HTMLCanvasElement, ctx:CanvasRenderingContext2D, anno:HTMLElement, renderedKey:string|null}>} */
  const pageNodes = new Map();
  /** @type {IntersectionObserver|null} */
  let renderObserver = null;
  /** @type {IntersectionObserver|null} */
  let activeObserver = null;

  function updateNav() {
    if (prevPage) prevPage.disabled = state.pageNum <= 1;
    if (nextPage) nextPage.disabled = state.pageNum >= (state.pdfDoc?.numPages || 1);
    if (pageNumber) pageNumber.value = String(state.pageNum);
  }

  function setMode(mode) {
    state.mode = formatMode(mode);
    safeLocalStorageSet("pdf.mode", state.mode);
    if (modeSelect) modeSelect.value = state.mode;
  }

  function setZoom(next) {
    state.zoom = parseZoomValue(next);
    safeLocalStorageSet("pdf.zoom", typeof state.zoom === "number" ? String(state.zoom) : state.zoom);
    if (zoomSelect) zoomSelect.value = String(state.zoom);
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
      mode: state.mode,
      page: state.pageNum,
      zoom: typeof state.zoom === "number" ? String(state.zoom) : state.zoom,
      rotate: state.rotate ? String(state.rotate) : null,
    });
  }

  function showViews() {
    const isPage = state.mode === "page";
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
      canvas.width = Math.floor(viewport.width * outputScale);
      canvas.height = Math.floor(viewport.height * outputScale);
      canvas.style.width = `${Math.floor(viewport.width)}px`;
      canvas.style.height = `${Math.floor(viewport.height)}px`;

      annoLayer.style.width = canvas.style.width;
      annoLayer.style.height = canvas.style.height;

      ctx.setTransform(outputScale, 0, 0, outputScale, 0, 0);
      ctx.imageSmoothingEnabled = true;
      ctx.imageSmoothingQuality = "high";
      await page.render({ canvasContext: ctx, viewport }).promise;

      await renderLinkAnnotations({
        pdfDoc: state.pdfDoc,
        page,
        viewport,
        layerEl: annoLayer,
        onGoToPage: (n) => goToPage(n),
        onNamedAction: (action) => goToNamedAction(action),
      });

      document.title = `${basename(file)} · ${state.pageNum}/${state.pdfDoc.numPages}`;
      if (subtitle) subtitle.textContent = `${file} · ${state.pageNum}/${state.pdfDoc.numPages}`;
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
    node.canvas.width = Math.floor(viewport.width * outputScale);
    node.canvas.height = Math.floor(viewport.height * outputScale);
    node.canvas.style.width = `${Math.floor(viewport.width)}px`;
    node.canvas.style.height = `${Math.floor(viewport.height)}px`;

    node.anno.style.width = node.canvas.style.width;
    node.anno.style.height = node.canvas.style.height;

    node.ctx.setTransform(outputScale, 0, 0, outputScale, 0, 0);
    node.ctx.imageSmoothingEnabled = true;
    node.ctx.imageSmoothingQuality = "high";
    await page.render({ canvasContext: node.ctx, viewport }).promise;

    await renderLinkAnnotations({
      pdfDoc: state.pdfDoc,
      page,
      viewport,
      layerEl: node.anno,
      onGoToPage: (n) => goToPage(n),
      onNamedAction: (action) => goToNamedAction(action),
    });
  }

  function setupObservers() {
    if (renderObserver) renderObserver.disconnect();
    if (activeObserver) activeObserver.disconnect();

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
      { root: null, rootMargin: "800px 0px", threshold: 0.01 },
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
      { root: null, rootMargin: "-45% 0px -50% 0px", threshold: [0.05, 0.1, 0.2, 0.35, 0.5, 0.7] },
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
    const node = pageNodes.get(pageNum);
    node?.el?.scrollIntoView({ behavior: "smooth", block: "start" });
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
      const node = pageNodes.get(state.pageNum);
      node?.el?.scrollIntoView({ behavior: "auto", block: "start" });
    });
  }

  modeSelect?.addEventListener("change", () => {
    setMode(modeSelect.value);
    applyModeAndRender();
  });

  prevPage?.addEventListener("click", () => goToPage(state.pageNum - 1));
  nextPage?.addEventListener("click", () => goToPage(state.pageNum + 1));

  pageNumber?.addEventListener("keydown", (ev) => {
    if (ev.key !== "Enter") return;
    const v = Number(pageNumber.value || "1");
    if (!Number.isFinite(v)) return;
    goToPage(v);
  });

  zoomSelect?.addEventListener("change", () => {
    setZoom(zoomSelect.value);
    if (state.mode === "scroll") invalidateScrollRenders();
    applyModeAndRender();
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
    if (state.mode === "page") {
      if (state.zoom === "page-width" || state.zoom === "page-fit") renderSinglePage();
      return;
    }
    if (state.zoom === "page-width" || state.zoom === "page-fit") {
      invalidateScrollRenders();
      applyModeAndRender();
    }
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
