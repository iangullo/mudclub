// ✅ app/javascript/controllers/helpers/svg_loader.js
import { deserializeSymbol } from "./svg_symbols"
import { deserializePath } from "./svg_paths"

let svgRoot = null

/**
 * Accessor to get the current active SVG root (if used externally).
 */
export function getSvgRoot() {
  return svgRoot
}

/**
 * Applies viewBox to ensure the court background fits the visible area.
 * @param {SVGSVGElement} svg - The main SVG container.
 * @param {SVGElement} background - The inserted background node (court).
 */
function zoomToFit(svg = svgRoot) {
  const background = svg?.querySelector(".court-background")
  if (!background || !background.getBBox) return

  const bbox = background.getBBox()
  if (!bbox || bbox.width === 0 || bbox.height === 0) return

  svg.setAttribute("viewBox", `${bbox.x} ${bbox.y} ${bbox.width} ${bbox.height}`)
  svg.setAttribute("preserveAspectRatio", "xMidYMid meet")
}

/**
 * Parses a raw SVG string and returns the corresponding SVG element.
 * @param {string} svgString - Raw SVG markup string.
 * @returns {SVGElement | null}
 */
function parseSVGElement(svgString) {
  if (!svgString || typeof svgString !== "string") return null

  const parser = new DOMParser()
  const doc = parser.parseFromString(svgString, "image/svg+xml")
  const svgElement = doc.documentElement

  if (svgElement.nodeName !== "svg" && svgElement.nodeName !== "symbol") {
    console.warn("Parsed SVG does not contain <svg> or <symbol> root")
    return null
  }
  return svgElement
}

/**
 * Deserializes an SVG element from a JS object representation.
 * Delegates to specific deserializers based on type.
 * @param {Object} data - Object describing the SVG element.
 * @returns {SVGElement | null}
 */
export function loadSVGElement(data) {
  if (!data || typeof data !== "object") return null

  switch (data.type) {
    case "symbol":
      return deserializeSymbol(data)
    case "path":
      return deserializePath(data)
    default:
      console.warn(`Unrecognised SVG type: ${data.type}`)
      return null
  }
}

/**
 * Inserts the court layout as a non-interactive background.
 * @param {SVGSVGElement} svg
 * @param {string} courtSymbolContent - Raw SVG <symbol> content for the court.
 */
export function insertCourtBackground(svg, courtSymbolContent) {
  const parsed = parseSVGElement(courtSymbolContent)
  if (!parsed) {
    console.warn("Court symbol parsing failed")
    return
  }

  const existing = svg.querySelector(".court-background")
  if (existing) existing.remove()

  const bg = parsed.cloneNode(true)
  bg.classList.add("court-background")
  bg.setAttribute("pointer-events", "none")

  svg.insertBefore(bg, svg.firstChild)

  // Adjust viewBox to fit background after rendering
  requestAnimationFrame(() => zoomToFit(svg))
}

/**
 * Loads a diagram (background + elements) into a target SVG element.
 * This function sets the court background and appends deserialized elements.
 * Does NOT perform serialization - only deserialization and rendering.
 * @param {SVGSVGElement} svg - Target SVG container.
 * @param {Object} data - Diagram data: { backgroundSvgContent: string, svgdata: Array<Object> }
 * @param {string} symbolNamespace - Optional prefix for <use> references (e.g., '#', '/assets/symbols.svg#').
 */
export function loadDiagram(svg, { backgroundSvgContent, svgdata }, symbolNamespace = "#") {
  if (!svg) {
    console.warn("Target SVG element is not provided")
    return
  }

  // Clear current contents except defs
  const defs = svg.querySelector("defs")
  svg.innerHTML = ""
  if (defs) svg.appendChild(defs)

  // Set global svgRoot reference
  svgRoot = svg

  // Insert the court background
  if (backgroundSvgContent) {
    insertCourtBackground(svg, backgroundSvgContent)
  }

  // Insert all SVG elements from svgdata
  if (Array.isArray(svgdata)) {
    svgdata.filter(item => item?.type).forEach(item => {
      const el = loadSVGElement(item)
      if (el) {
        // If element references symbols, fix href if needed
        if (symbolNamespace && el.hasAttribute("href")) {
          const href = el.getAttribute("href")
          if (!href.startsWith("#") && !href.startsWith(symbolNamespace)) {
            el.setAttribute("href", symbolNamespace + href)
          }
        }
        svg.appendChild(el)
      } else {
        console.warn("Failed to load one SVG element in diagram")
      }
    })
  }
}
