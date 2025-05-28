// app/javascript/controllers/helpers/svg_loader.js
import { deserializeSymbol } from "helpers/svg_symbols"
import { deserializePath } from "helpers/svg_paths"
import { loadSvgMarkers } from "helpers/svg_markers"
import { createSvgElement, getSvgScale } from "helpers/svg_utils"

let svgRoot = null
const DEBUG = false

const deserializers = {
  path: deserializePath,
  symbol: deserializeSymbol,
}

export function getSvgRoot() {
  return svgRoot
}

/**
 * Adjusts the SVG viewBox to fit the court background bounding box exactly.
 * This naturally scales all SVG children uniformly.
 */

export function zoomToFit(svg, img) {
  if (!svg || !img) {
    DEBUG && console.error("Invalid image dimensions.")
    return
  }

  // Get available size
  const availableWidth = window.innerWidth - 20
  const availableHeight = window.innerHeight - 250

  const viewBox = svg.viewBox.baseVal
  const aspectRatio = viewBox.width / viewBox.height

  // Compute dimensions
  let width = availableWidth
  let height = width / aspectRatio

  if (height > availableHeight) {
    height = availableHeight
    width = height * aspectRatio
  }

  // Apply styles directly to SVG
  svg.style.width = `${width}px`
  svg.style.height = `${height}px`

  if (DEBUG) {
    console.log(`limits: ${availableWidth} x ${availableHeight}`)
    console.log(`new container: ${width} x ${height}`)
  }

  svg.setAttribute("width", width)
  svg.setAttribute("height", height)
  svg.setAttribute("preserveAspectRatio", "xMidYMid meet")
  return getSvgScale(svg)
}

/**
 * Delegates deserialization to specific deserializers based on the element type.
 */
export function loadSVGElement(data) {
  if (!data?.type) return null
  const fn = deserializers[data.type]
  return fn ? fn(data) : null
}

/**
 * Loads the full diagram (court + symbols/paths) into the SVG container.
 * Preserves <defs>, loads markers, and sets viewBox to fit court background.
 */
export function loadDiagram(canvas, court, svgdata) {
  if (!canvas) {
    DEBUG && console.warn("Target SVG canvas is not provided")
    return
  }

  if (DEBUG) {
    console.log("canvas: ", canvas)
    console.log("court: ", court)
    console.log("svgdata: ", svgdata)
  }

  // load markers for arrows
  let defs = canvas.querySelector("defs")
  if (!defs) {
    defs = createSvgElement("defs")
    canvas.insertBefore(defs, canvas.firstChild)
  }

  // Load shared markers
  loadSvgMarkers(defs)

  // SETUP SCALING for the court size --- How to store scaling dynamically?
  requestAnimationFrame(() => {zoomToFit(canvas, court)})

  // Insert all symbols and paths from svgdata
  if (Array.isArray(svgdata)) {
    svgdata.forEach(item => {
      if (!item?.type) return
      const el = loadSVGElement(item)
      if (!el) {
        DEBUG && console.warn("Failed to deserialize SVG element", item)
        return
      }

      // Append element at top level (above background)
      canvas.appendChild(el)
    })
  }
}
