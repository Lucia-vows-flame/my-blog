/* global pdfjsLib */

const WORKER_SRC = "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js";

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

function clamp(n, lo, hi) {
  return Math.min(hi, Math.max(lo, n));
}

function basename(path) {
  const s = String(path || "");
  const parts = s.split("/");
  return parts[parts.length - 1] || s;
}

function isPdfJsReady() {
  return typeof pdfjsLib !== "undefined" && pdfjsLib?.getDocument;
}

function showError(message, { file } = {}) {
  const error = qs("error");
  const loading = qs("loading");
  const canvasWrap = qs("canvas-wrap");
  if (loading) loading.hidden = true;
  if (canvasWrap) canvasWrap.hidden = true;

  if (!error) return;
  error.hidden = false;
  const fileHint = file ? `（文件：<code>${escapeHtml(file)}</code>）` : "";
  const rawLink = file ? `<a class="pdf-btn pdf-btn--link" href="${escapeAttr(file)}" target="_blank" rel="noopener noreferrer">打开原始 PDF</a>` : "";
  error.innerHTML =
    `<div style="font-weight:700;margin-bottom:6px">PDF 加载失败</div>` +
    `<div style="color:rgba(255,255,255,.72);line-height:1.6">` +
    `${escapeHtml(message)} ${fileHint}` +
    `</div>` +
    (rawLink ? `<div style="margin-top:12px">${rawLink}</div>` : "");
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

function parseZoomValue(v) {
  if (v === "page-width" || v === "page-fit") return v;
  const n = Number(v);
  if (!Number.isFinite(n)) return "page-width";
  return clamp(n, 0.25, 4);
}

function formatPercent(v) {
  if (typeof v !== "number") return "";
  return `${Math.round(v * 100)}%`;
}

function toUrl(file) {
  try {
    return new URL(file, location.href).toString();
  } catch {
    return String(file || "");
  }
}

async function main() {
  const params = parseHashParams();
  const file = params.file || "";
  const pageParam = Number(params.page || "1");
  const zoomParam = parseZoomValue(params.zoom || "page-width");
  const rotateParam = Number(params.rotate || "0");

  if (!file) {
    showError("缺少参数：file", {});
    return;
  }

  const title = qs("pdf-title");
  const subtitle = qs("pdf-subtitle");
  if (title) title.textContent = basename(file);
  if (subtitle) subtitle.textContent = file;

  const openRaw = qs("open-raw");
  const download = qs("download");
  if (openRaw) openRaw.setAttribute("href", file);
  if (download) download.setAttribute("href", file);

  const loadingText = qs("loading-text");
  if (loadingText) loadingText.textContent = `正在加载：${basename(file)}`;

  if (!isPdfJsReady()) {
    showError("PDF.js 未加载（可能是网络受限或 CDN 不可用）。", { file });
    return;
  }

  pdfjsLib.GlobalWorkerOptions.workerSrc = WORKER_SRC;

  const canvas = qs("pdf-canvas");
  const canvasWrap = qs("canvas-wrap");
  const loading = qs("loading");
  const pageNumber = qs("page-number");
  const pageCount = qs("page-count");
  const prevPage = qs("prev-page");
  const nextPage = qs("next-page");
  const zoomSelect = qs("zoom-select");
  const zoomIn = qs("zoom-in");
  const zoomOut = qs("zoom-out");
  const rotateBtn = qs("rotate");

  if (!canvas || !canvasWrap) {
    showError("Viewer DOM 不完整。", { file });
    return;
  }

  /** @type {{pdfDoc: any, pageNum: number, zoom: any, rotate: number, rendering: boolean, pending: boolean}} */
  const state = {
    pdfDoc: null,
    pageNum: Number.isFinite(pageParam) ? clamp(pageParam, 1, 999999) : 1,
    zoom: zoomParam,
    rotate: Number.isFinite(rotateParam) ? rotateParam : 0,
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
  if (zoomSelect) zoomSelect.value = String(state.zoom);

  const ctx = canvas.getContext("2d", { alpha: false });
  if (!ctx) {
    showError("Canvas context 创建失败。", { file });
    return;
  }

  function setLoadingVisible(v) {
    if (loading) loading.hidden = !v;
    if (canvasWrap) canvasWrap.hidden = v;
  }

  function updateNav() {
    if (prevPage) prevPage.disabled = state.pageNum <= 1;
    if (nextPage) nextPage.disabled = state.pageNum >= (state.pdfDoc?.numPages || 1);
    if (pageNumber) pageNumber.value = String(state.pageNum);
    if (zoomSelect && typeof state.zoom === "number") {
      const known = new Set(["0.5", "0.75", "1", "1.25", "1.5", "2"]);
      const s = String(state.zoom);
      zoomSelect.value = known.has(s) ? s : s;
    } else if (zoomSelect) {
      zoomSelect.value = String(state.zoom);
    }
  }

  function computeScale(viewport, container) {
    if (typeof state.zoom === "number") return state.zoom;
    const pad = 32; // canvasWrap padding
    const cw = Math.max(200, container.clientWidth - pad);
    const ch = Math.max(200, container.clientHeight - pad);
    if (state.zoom === "page-fit") {
      const sx = cw / viewport.width;
      const sy = ch / viewport.height;
      return clamp(Math.min(sx, sy), 0.25, 4);
    }
    // page-width
    return clamp(cw / viewport.width, 0.25, 4);
  }

  async function renderPage() {
    if (state.rendering) {
      state.pending = true;
      return;
    }
    state.rendering = true;
    state.pending = false;
    setLoadingVisible(true);

    try {
      const page = await state.pdfDoc.getPage(state.pageNum);
      const baseViewport = page.getViewport({ scale: 1, rotation: state.rotate });
      const stage = qs("stage") || canvasWrap;
      const scale = computeScale(baseViewport, stage);
      const viewport = page.getViewport({ scale, rotation: state.rotate });

      const outputScale = window.devicePixelRatio || 1;
      canvas.width = Math.floor(viewport.width * outputScale);
      canvas.height = Math.floor(viewport.height * outputScale);
      canvas.style.width = `${Math.floor(viewport.width)}px`;
      canvas.style.height = `${Math.floor(viewport.height)}px`;

      ctx.setTransform(outputScale, 0, 0, outputScale, 0, 0);
      ctx.imageSmoothingEnabled = true;
      ctx.imageSmoothingQuality = "high";

      await page.render({ canvasContext: ctx, viewport }).promise;

      document.title = `${basename(file)} · ${state.pageNum}/${state.pdfDoc.numPages}`;
      if (subtitle) subtitle.textContent = `${file} · ${state.pageNum}/${state.pdfDoc.numPages} · ${typeof state.zoom === "number" ? formatPercent(scale) : zoomSelect?.selectedOptions?.[0]?.textContent || ""}`;
    } finally {
      setLoadingVisible(false);
      state.rendering = false;
      updateNav();
      setHashParams({
        file,
        page: state.pageNum,
        zoom: typeof state.zoom === "number" ? String(state.zoom) : state.zoom,
        rotate: state.rotate ? String(state.rotate) : null,
      });
      if (state.pending) queueMicrotask(renderPage);
    }
  }

  function setZoom(next) {
    state.zoom = parseZoomValue(next);
  }

  function zoomBy(delta) {
    const current = typeof state.zoom === "number" ? state.zoom : 1;
    const next = clamp(Math.round((current + delta) * 100) / 100, 0.25, 4);
    state.zoom = next;
    if (zoomSelect) zoomSelect.value = String(next);
  }

  prevPage?.addEventListener("click", () => {
    state.pageNum = clamp(state.pageNum - 1, 1, state.pdfDoc.numPages);
    renderPage();
  });
  nextPage?.addEventListener("click", () => {
    state.pageNum = clamp(state.pageNum + 1, 1, state.pdfDoc.numPages);
    renderPage();
  });

  pageNumber?.addEventListener("keydown", (ev) => {
    if (ev.key !== "Enter") return;
    const v = Number(pageNumber.value || "1");
    if (!Number.isFinite(v)) return;
    state.pageNum = clamp(Math.trunc(v), 1, state.pdfDoc.numPages);
    renderPage();
  });

  zoomSelect?.addEventListener("change", () => {
    setZoom(zoomSelect.value);
    renderPage();
  });
  zoomIn?.addEventListener("click", () => {
    zoomBy(0.1);
    renderPage();
  });
  zoomOut?.addEventListener("click", () => {
    zoomBy(-0.1);
    renderPage();
  });
  rotateBtn?.addEventListener("click", () => {
    state.rotate = (state.rotate + 90) % 360;
    renderPage();
  });

  window.addEventListener("resize", () => {
    if (state.zoom === "page-width" || state.zoom === "page-fit") renderPage();
  });

  window.addEventListener("hashchange", () => {
    const p = parseHashParams();
    if (p.file && p.file !== file) return; // changing file requires reload

    const nextPageNum = Number(p.page || state.pageNum);
    const nextZoom = parseZoomValue(p.zoom || state.zoom);
    const nextRotate = Number(p.rotate || state.rotate);

    let changed = false;
    if (Number.isFinite(nextPageNum) && Math.trunc(nextPageNum) !== state.pageNum) {
      state.pageNum = clamp(Math.trunc(nextPageNum), 1, state.pdfDoc.numPages);
      changed = true;
    }
    if (String(nextZoom) !== String(state.zoom)) {
      state.zoom = nextZoom;
      if (zoomSelect) zoomSelect.value = String(nextZoom);
      changed = true;
    }
    if (Number.isFinite(nextRotate) && nextRotate !== state.rotate) {
      state.rotate = nextRotate;
      changed = true;
    }
    if (changed) renderPage();
  });

  window.addEventListener("keydown", (ev) => {
    if (ev.altKey || ev.ctrlKey || ev.metaKey) return;
    if (ev.key === "ArrowLeft") {
      ev.preventDefault();
      state.pageNum = clamp(state.pageNum - 1, 1, state.pdfDoc.numPages);
      renderPage();
    } else if (ev.key === "ArrowRight") {
      ev.preventDefault();
      state.pageNum = clamp(state.pageNum + 1, 1, state.pdfDoc.numPages);
      renderPage();
    } else if (ev.key === "+" || ev.key === "=") {
      ev.preventDefault();
      zoomBy(0.1);
      renderPage();
    } else if (ev.key === "-" || ev.key === "_") {
      ev.preventDefault();
      zoomBy(-0.1);
      renderPage();
    } else if (ev.key.toLowerCase() === "r") {
      ev.preventDefault();
      state.rotate = (state.rotate + 90) % 360;
      renderPage();
    }
  });

  renderPage();
}

main().catch((err) => {
  const params = parseHashParams();
  showError(String(err?.message || err || "unknown error"), { file: params.file || "" });
});

