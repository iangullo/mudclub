// ✅ app/javascript/controllers/helpers/svg_markers.js
import { createSvgElement } from "helpers/svg_utils"

export function loadSvgMarkers(defs = null) {
  if (!defs) {
    let svg = document.getElementById("svg-markers")
    if (!svg) {
      svg = createSvgElement("svg")
      svg.setAttribute("id", "svg-markers")
      svg.setAttribute("style", "display: none")
      defs = createSvgElement("defs")
      svg.appendChild(defs)
      document.body.appendChild(svg)
    } else {
      defs = svg.querySelector("defs")
    }
  }

  appendMarkerIfMissing(defs, arrowheadMarker)
  appendMarkerIfMissing(defs, terminatorTMarker)
}

// --- Internal helpers ---

function appendMarkerIfMissing(defs, markerFn) {
  const marker = markerFn()
  if (marker && !defs.querySelector(`#${marker.id}`)) {
    defs.appendChild(marker)
  }
}

function arrowheadMarker() {
  const marker = createSvgElement("marker")
  marker.setAttribute("id", "arrowhead")
  marker.setAttribute("viewBox", "0 0 10 10")
  marker.setAttribute("refX", "8")
  marker.setAttribute("refY", "5")
  marker.setAttribute("markerWidth", "6")
  marker.setAttribute("markerHeight", "6")
  marker.setAttribute("orient", "auto-start-reverse")

  const path = createSvgElement("path")
  path.setAttribute("d", "M 0 0 L 10 5 L 0 10 z")
  path.setAttribute("class", "fill-current")

  marker.appendChild(path)
  return marker
}

function terminatorTMarker() {
  const marker = createSvgElement("marker")
  marker.setAttribute("id", "terminator-T")
  marker.setAttribute("viewBox", "0 0 10 10")
  marker.setAttribute("refX", "5")
  marker.setAttribute("refY", "5")
  marker.setAttribute("markerWidth", "6")
  marker.setAttribute("markerHeight", "6")
  marker.setAttribute("orient", "auto")

  const path = createSvgElement("path")
  path.setAttribute("d", "M 0 0 L 10 0")
  path.setAttribute("class", "stroke-current")
  path.setAttribute("stroke-width", "2")

  marker.appendChild(path)
  return marker
}
