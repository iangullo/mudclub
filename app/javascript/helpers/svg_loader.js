// app/javascript/helpers/svg_loader.js
import { getSvgScale, isSVGElement, setAttributes } from "helpers/svg_utils"
import { createSymbol } from "helpers/svg_symbols"
import { createPath } from "helpers/svg_paths"

const DEBUG = false

// Loads SVG content to view/edit
export function loadDiagramContent(container, data, isEditor = false) {
  const svgdata = JSON.parse(data) || '{}'

  DEBUG && console.log('loadDiagramContent: ', container, svgdata, isEditor)
  if (!isSVGElement(container)) return result

  // load paths & symbols
  loadPaths(container, svgdata?.paths)
  return loadSymbols(container, svgdata?.symbols, isEditor)
}

/**
 * Finds the lowest available number in a Set
 * @param {Set<number>} numberSet 
 * @returns {number}
 */
export function findLowestAvailableNumber(numberSet) {
  let i = 1
  while (numberSet.has(i)) i++
  return i
}

/**
 * Validates SVG structure meets minimum requirements
 * @param {SVGElement} svgContainer 
 * @returns {boolean}
 */
export function validateDiagram(svgContainer) {
  if (!svgContainer?.querySelector) return false
  return true
}

/**
 * Adjusts the SVG viewBox to fit the court background bounding box exactly.
 * This naturally scales all SVG children uniformly.
 */
export function zoomToFit(svg, court, isEditor = false) {
  if (!svg || !court || !court.viewBox) {
    DEBUG && console.error("zoomToFit: Invalid SVG or court element")
    return 1
  }

  const viewBox = court.viewBox?.baseVal || court.getBBox()
  const aspectRatio = viewBox.width / viewBox.height
  let availableWidth = viewBox.width
  let availableHeight = viewBox.height
  DEBUG && console.log(`initial limits: ${availableWidth} x ${availableHeight}`)

  if (isEditor) { // Get max available size
    availableWidth = window.innerWidth - 20
    availableHeight = window.innerHeight - 250
    DEBUG && console.log(`editor limits: ${availableWidth} x ${availableHeight}`)

  } else { // Get the container element (SVG's parent)
    const container = svg.parentElement
    if (!container) {
      DEBUG && console.log("zoomToFit: SVG has no parent container");
      return 1
    }
    DEBUG && console.log("viewer container: ", container)
    const containerStyle = getComputedStyle(container)
    availableWidth = parseFloat(containerStyle.width)
    availableHeight = parseFloat(containerStyle.height)
    DEBUG && console.log("viewer limits: ", availableWidth, " x ", availableHeight)
  }


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
  svg.style.margin = '0 auto';
  svg.style.display = 'block';

  if (DEBUG) {
    console.log(`limits: ${availableWidth} x ${availableHeight}`)
    console.log(`new container: ${width} x ${height}`)
  }

  setAttributes(svg, { "width": width, "height": height, "preserveAspectRatio": "xMidYMid meet" })
  return getSvgScale(svg)
}

// Create symbols from symbol data
function loadSymbols(svg, symbols = [], isEditor = false) {
  const height = svg.getBBox().height
  const result = isEditor ? { attackers: new Set(), defenders: new Set() } : true

  symbols.forEach(symbol => {
    DEBUG && console.log('Found symbol definition: ', symbol)
    const symbolGroup = createSymbol(symbol, height)
    if (['attacker', 'defender'].includes(symbol.kind)) {
      const number = parseInt(symbol.label)
      if (isNaN(number)) {
        DEBUG && console.log(`Invalid number in label: ${label.textContent}`)
        return
      }

      DEBUG && console.log(`Found ${symbol.kind} with number ${number}`)
      if (isEditor) {
        result[symbol.kind === 'attacker' ? 'attackers' : 'defenders'].add(number)
      }
    }
    svg.appendChild(symbolGroup)
  })
  return result
}

// Create paths from path data
function loadPaths(svg, paths = []) {
  paths.forEach(path => {
    DEBUG && console.log('Found path definition: ', path)
    const pathGroup = createPath(path.points,
      {
        curve: path.curve === "true",
        style: path.style,
        ending: path.ending,
        stroke: path.stroke,
        transform: "",
        isPreview: false
      }
    )
    svg.appendChild(pathGroup)
  })
}
