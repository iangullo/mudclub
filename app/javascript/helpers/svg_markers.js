// ✅ app/javascript/controllers/helpers/svg_markers.js
import { createSVGElement } from "./svg_utils.js"

export function addMarker(markerFn) {
  let svg = document.getElementById("svg-markers")
  if (!svg) {
    svg = createSVGElement("svg")
    svg.setAttribute("id", "svg-markers")
    svg.setAttribute("style", "display: none")
    const defs = createSVGElement("defs")
    svg.appendChild(defs)
    document.body.appendChild(svg)
  }

  const defs = svg.querySelector("defs")
  const marker = markerFn()
  if (marker) defs.appendChild(marker)
}

export function ensureSVGMarkersLoaded() {
  addMarker(arrowheadMarker)
  addMarker(terminatorTMarker)
}

function arrowheadMarker() {
  const marker = createSVGElement("marker")
  marker.setAttribute("id", "arrowhead")
  marker.setAttribute("viewBox", "0 0 10 10")
  marker.setAttribute("refX", "8")
  marker.setAttribute("refY", "5")
  marker.setAttribute("markerWidth", "6")
  marker.setAttribute("markerHeight", "6")
  marker.setAttribute("orient", "auto-start-reverse")

  const path = createSVGElement("path")
  path.setAttribute("d", "M 0 0 L 10 5 L 0 10 z")
  path.setAttribute("class", "fill-current")

  marker.appendChild(path)
  return marker
}

function terminatorTMarker() {
  const marker = createSVGElement("marker")
  marker.setAttribute("id", "terminator-T")
  marker.setAttribute("viewBox", "0 0 10 10")
  marker.setAttribute("refX", "5")
  marker.setAttribute("refY", "5")
  marker.setAttribute("markerWidth", "6")
  marker.setAttribute("markerHeight", "6")
  marker.setAttribute("orient", "auto")

  const path = createSVGElement("path")
  path.setAttribute("d", "M 0 0 L 10 0")
  path.setAttribute("class", "stroke-current")
  path.setAttribute("stroke-width", "2")

  marker.appendChild(path)
  return marker
}
