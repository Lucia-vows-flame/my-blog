const BRAND_LOGO_URL = "assets/icons/logo.svg?v=20260311logo5";
const BACKGROUND_SUBPATH = "M0 10000 l0 -10000 10000 0 10000 0 0 10000 0 10000 -10000 0 -10000 0 0 -10000z ";

function cleanBrandSvg(raw) {
  return String(raw || "")
    .replace(/<\?xml[\s\S]*?\?>/i, "")
    .replace(/<!DOCTYPE[\s\S]*?>/i, "")
    .replace(/<metadata>[\s\S]*?<\/metadata>/i, "")
    .replace(BACKGROUND_SUBPATH, "");
}

async function hydrateBrandLogos() {
  const mounts = [...document.querySelectorAll("svg.navbar-brand__mark.header-logo")];
  if (!mounts.length) return;

  try {
    const res = await fetch(BRAND_LOGO_URL, { cache: "no-store" });
    if (!res.ok) throw new Error(`Failed to load logo: ${res.status}`);

    const parser = new DOMParser();
    const doc = parser.parseFromString(cleanBrandSvg(await res.text()), "image/svg+xml");
    if (doc.querySelector("parsererror")) throw new Error("Invalid logo SVG");

    const svg = doc.documentElement;
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

