// app/javascript/helpers/svg_markers.js
import { createSvgElement } from "helpers/svg_utils"

const MARKER_SIZE = 10
const MARKER_REF_X = 8
const MARKER_REF_Y = 5

export function applyMarker(pathElement, type) {
  // Clear previous markers
  pathElement.removeAttribute('marker-end')

  if (!type || type === 'none') return

  const markerId = `marker-${type}`
  let marker = document.getElementById(markerId)

  if (!marker) {
    marker = createSvgElement('marker')
    marker.id = markerId
    marker.setAttribute('markerWidth', MARKER_SIZE)
    marker.setAttribute('markerHeight', MARKER_SIZE)
    marker.setAttribute('refX', MARKER_REF_X)
    marker.setAttribute('refY', MARKER_REF_Y)
    marker.setAttribute('orient', 'auto')
    marker.setAttribute('viewBox', `0 0 ${MARKER_SIZE} ${MARKER_SIZE}`)

    const symbol = createSvgElement('path')
    const strokeColor = pathElement.getAttribute('color') || '#000'
    symbol.setAttribute('fill', strokeColor)
    symbol.setAttribute('stroke', strokeColor)

    if (type === 'arrow') {
      symbol.setAttribute('d', `M0,0 L${MARKER_SIZE},${MARKER_SIZE/2} L0,${MARKER_SIZE} Z`)
    } else {  // 'tee'
      symbol.setAttribute('d', `M0,${MARKER_SIZE/2} L${MARKER_SIZE},${MARKER_SIZE/2} M${MARKER_SIZE/2},0 L${MARKER_SIZE/2},${MARKER_SIZE}`)
      symbol.setAttribute('stroke-width', '2')
    }

    marker.appendChild(symbol)
    // Ensure defs exists
    let defs = document.querySelector('defs')
    if (!defs) {
      defs = createSvgElement('defs')
      document.querySelector('svg').prepend(defs)
    }
    defs.appendChild(marker)
  }

  pathElement.setAttribute('marker-end', `url(#${markerId})`)
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
