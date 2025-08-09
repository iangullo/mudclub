// app/javascript/helpers/svg_markers.js
import { createSvgElement, setAttributes } from "helpers/svg_utils"

const MARKER_SIZE = 5
const MARKER_HALF = MARKER_SIZE / 2
const MARKER_DOUBLE = MARKER_SIZE * 2
const DEBUG = false

export function applyMarker(pathElement, ending) {
  DEBUG && console.log("applyMarker ", pathElement, ending)

  // Clear previous markers
  pathElement.removeAttribute('marker-end')
  if (!ending || ending === 'none') return
  
  let marker = document.getElementById(markerId(ending))
  if (!marker) {
    const color = pathElement.getAttribute('color') || '#000'
    marker = createMarkerElement(ending, color)
  
    // Ensure defs exists
    let defs = document.querySelector('defs')
    if (!defs) {
      defs = createSvgElement('defs')
      document.querySelector('svg').prepend(defs)
    }
    defs.appendChild(marker)
    DEBUG && console.log("appending marker defitinion: ", marker)
  }
  if (marker) pathElement.setAttribute('marker-end', `url(#${markerId(ending)})`)
}

// internal functions
function createMarkerElement(ending, color) {
  const marker = createSvgElement('marker')
  marker.id = markerId(ending)
  setAttributes(marker, {'markerWidth': MARKER_SIZE, 'orient': 'auto'})
  const symbol = createSvgElement('path')
  setAttributes(symbol, {'fill': color, 'stroke': color})
  marker.appendChild(symbol)
  switch (ending) {
    case 'arrow':
      setupArrowMarker(marker)
      break
    case 'tee':
      setupTeeMarker(marker)
      break
    default:
      return null
  }

  return marker
}

function markerId(ending) {
  return `marker-${ending}`
}

function setupArrowMarker(marker) {
  setAttributes(marker, {
    'markerHeight': MARKER_SIZE,
    'refX': MARKER_SIZE,
    'refY': MARKER_HALF,
    'viewBox': `0 0 ${MARKER_SIZE} ${MARKER_SIZE}`
  })
  const symbol = marker.firstElementChild
  symbol.setAttribute('d', `M0,0 L${MARKER_SIZE},${MARKER_HALF} L0,${MARKER_SIZE} Z`)
}

function setupTeeMarker(marker) {
  setAttributes(marker, {
    'markerHeight': MARKER_DOUBLE,
    'refX': MARKER_HALF,
    'refY': MARKER_SIZE,
    'viewBox': `0 0 ${MARKER_SIZE} ${MARKER_DOUBLE}`
  })
  const symbol = marker.firstElementChild
  symbol.setAttribute('d', `M${-MARKER_SIZE},0 M${MARKER_HALF},0 V${MARKER_DOUBLE}`)
  symbol.setAttribute('stroke-width', MARKER_HALF)
}