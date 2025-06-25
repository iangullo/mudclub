// app/javascript/helpers/svg_loader.js
import { getSvgScale } from "helpers/svg_utils"

const DEBUG = false

/**
 * Parses SVG content and tracks player numbers
 * @param {SVGElement} svgContainer 
 * @returns {{
 *   attackers: Set<number>,
 *   defenders: Set<number>,
 * }}
 */
export function parseDiagramContent(svgContainer) {
  const result = {
    attackers: new Set(),
    defenders: new Set()
  }

  if (!svgContainer) return result

  // Look for wrapper elements containing attacker/defender symbols
  const wrappers = svgContainer.querySelectorAll('g.wrapper[type="symbol"]')
  DEBUG && console.log(`Found ${wrappers.length} symbol wrappers`)

  wrappers.forEach(wrapper => {    // Find the inner element with the actual kind
    const inner = wrapper.querySelector('[data-kind]')
    if (!inner) {
      DEBUG && console.log("Wrapper contains no inner element with data-kind", wrapper)
      return
    }

    const kind = inner.dataset.kind
    if (!['attacker', 'defender'].includes(kind)) {
      DEBUG && console.log(`Skipping non-player symbol of kind ${kind}`)
      return
    }
    DEBUG && console.log(`Found ${kind} ${inner.dataset.id}`)

    // Get the number from the label
    const number = parseInt(inner.textContent)
    if (isNaN(number)) {
      DEBUG && console.log(`Invalid number in label: ${label.textContent}`)
      return
    }

    DEBUG && console.log(`Found ${kind} with number ${number}`)
    result[kind === 'attacker' ? 'attackers' : 'defenders'].add(number)
  })
  
  DEBUG && console.log('Parsed diagram content:', {
    attackers: Array.from(result.attackers),
    defenders: Array.from(result.defenders)
  })

  return result
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
