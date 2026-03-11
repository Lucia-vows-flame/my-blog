const BRAND_LOGO_URL = "assets/icons/logo.svg?v=20260311logo6";
const BACKGROUND_PATH_PREFIX =
  /^M0\s+10000\s+l0\s+-10000\s+10000\s+0\s+10000\s+0\s+0\s+10000\s+0\s+10000\s+-10000\s+0\s+-10000\s+0\s+0\s+-10000z\s*m/i;

function stripSvgPrologue(raw) {
  return String(raw || "")
    .replace(/<\?xml[\s\S]*?\?>/i, "")
    .replace(/<!DOCTYPE[\s\S]*?>/i, "")
    .replace(/<metadata>[\s\S]*?<\/metadata>/i, "");
}

function normalizeLogoShape(svg) {
  const firstPath = svg.querySelector("path");
  if (!(firstPath instanceof SVGPathElement)) return;

  const d = firstPath.getAttribute("d") || "";
  const cleaned = d.replace(BACKGROUND_PATH_PREFIX, "M").replace(/^m10612\b/, "M10612");
  if (cleaned && cleaned !== d) firstPath.setAttribute("d", cleaned);
}

async function hydrateBrandLogos() {
  const mounts = [...document.querySelectorAll("svg.navbar-brand__mark.header-logo")];
  if (!mounts.length) return;

  try {
    const res = await fetch(BRAND_LOGO_URL, { cache: "no-store" });
    if (!res.ok) throw new Error(`Failed to load logo: ${res.status}`);

    const parser = new DOMParser();
    const doc = parser.parseFromString(stripSvgPrologue(await res.text()), "image/svg+xml");
    if (doc.querySelector("parsererror")) throw new Error("Invalid logo SVG");

    const svg = doc.documentElement;
    normalizeLogoShape(svg);
    svg.classList.add("navbar-brand__mark", "header-logo", "is-hydrated");
    svg.setAttribute("aria-hidden", "true");
    svg.setAttribute("focusable", "false");
    svg.removeAttribute("width");
    svg.removeAttribute("height");

    for (const mount of mounts) {
      mount.replaceWith(svg.cloneNode(true));
    }
  } catch (error) {
    console.error(error);
  }
}

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", hydrateBrandLogos, { once: true });
} else {
  hydrateBrandLogos();
}
