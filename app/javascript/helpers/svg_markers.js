// app/javascript/helpers/svg_markers.js
import { createSvgElement, generateId, setAttributes } from "helpers/svg_utils"

const MARKER_SIZE = 5
const MARKER_HALF = MARKER_SIZE / 2
const MARKER_DOUBLE = MARKER_SIZE * 2
const DEBUG = false

export function applyMarkerColor(pathElement, color) {
  const markerEnd = pathElement.getAttribute('marker-end')
  if (!markerEnd) return

  // Extract marker ID from the URL
  const markerId = markerEnd.replace('url(#', '').replace(')', '')
  const marker = document.getElementById(markerId)

  if (marker) {
    const markerPath = marker.querySelector('path')
    if (markerPath) {
      markerPath.setAttribute('stroke', color)
      markerPath.setAttribute('fill', color)
    }
  }
}

export function createMarker(pathGroup, ending, color) {
  DEBUG && console.log("createMarker ", pathGroup, ending, color)
  const basePath = pathGroup.querySelector('path')
  if (!basePath) return

  const markerId = `marker-${ending}-${generateId()}`
  const marker = createMarkerElement(ending, color)
  marker.id = markerId

  // Ensure defs exists
  let defs = document.querySelector('defs')
  if (!defs) {
    defs = createSvgElement('defs')
    document.querySelector('svg').prepend(defs)
  }
  defs.appendChild(marker)

  // Set the marker on the path
  basePath.setAttribute('marker-end', `url(#${markerId})`)
}

// internal functions
function createMarkerElement(ending, color) {
  const marker = createSvgElement('marker')
  marker.id = markerId(ending)
  setAttributes(marker, { 'markerWidth': MARKER_SIZE, 'orient': 'auto' })
  const symbol = createSvgElement('path')
  setAttributes(symbol, { 'fill': color, 'stroke': color })
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