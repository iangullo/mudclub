// app/javascript/helpers/svg_paths.js
import { createGroup, createSvgElement, generateId, isSVGElement, setAttributes, wrapContent } from "helpers/svg_utils"
import { applyPathStyle } from "helpers/svg_styles"
import { applyMarkerColor, createMarker } from "helpers/svg_markers"

export const MIN_POINTS_FOR_CURVE = 3
const TEMP_COLOR = '#888888'
const TEMP_OPACITY = 0.5
const DEBUG = false

export function applyPathColor(pathElement, color) {
  DEBUG && console.log('applyPathColor()', pathElement, color)
  pathElement.dataset.color = color
  const mainPath = pathElement.querySelector('path')

  if (pathElement.dataset.style === 'double') {  // color 2 "fake" paths...
    const group = pathElement.querySelector('g.double-path')
    group?.querySelectorAll('path').forEach(path => { path.style.stroke = color })
  } else {
    mainPath.style.stroke = color
  }
  applyMarkerColor(mainPath, color)
}

export function createPath(points = [], options = {}) {
  DEBUG && console.log("createPath:", points, options)

  const vOpts = validateOptions(options)
  const pathId = generateId('path') // Generate ID once
  const pathElement = createSvgElement('path')

  // Create inner group
  const pathGroup = createGroup()
  pathGroup.setAttribute("id", pathId)
  pathGroup.classList.add("path")
  pathGroup.appendChild(pathElement)

  // Create a unique marker for this path if needed
  if (vOpts.ending && vOpts.ending !== 'none') {
    createMarker(pathGroup, vOpts.ending, vOpts.color);
  }

  updatePath(pathGroup, svgPoints(points), vOpts)

  // Create wrapper group
  return wrapContent(pathGroup, "path", false)
}

export function getPathPoints(pathElement) {
  const inner = pathElement
  const pointsData = inner.getAttribute('data-points')
  if (!pointsData) return []

  try {
    return JSON.parse(pointsData).map(([x, y]) => ({ x, y }))
  } catch (e) {
    console.error('Error parsing path points:', e)
    return []
  }
}

export function getPathOptions(pathElement) {
  if (pathElement) {
    return {
      curve: pathElement.dataset.curve === 'true',
      style: pathElement.dataset.style,
      ending: pathElement.dataset.ending,
      isPreview: pathElement.dataset.isPreview === 'true',
      color: pathElement.dataset.color
    }
  } else {
    return null
  }
}

export function setPathEditMode(pathGroup, isEditable, options = getPathOptions(pathGroup)) {
  DEBUG && console.warn(`setPathEditMode(${isEditable})`)
  if (!pathGroup) return

  const points = getPathPoints(pathGroup)
  options.isPreview = isEditable
  if (isEditable) {
    pathGroup.classList.add('editing')
    addControlPoints(pathGroup, points)
  } else {
    pathGroup.classList.remove('editing')
    removeControlPoints(pathGroup)
  }
  updatePath(pathGroup, points, options)
}

export function updatePath(pathGroup, points, options = getPathOptions(pathGroup)) {
  if (DEBUG) {
    console.log("updatePath ", pathGroup)
    console.log("options: ", options)
    console.log("points: ", points)
  }

  if (!isSVGElement(pathGroup)) return null
  const pathElement = pathGroup.querySelector('path')
  if (!isSVGElement(pathElement)) return null

  const pArray = JSON.stringify(points.map(p => [p.x, p.y]))
  const chgPts = (pArray !== getPathPoints(pathGroup))
  const vOpts = validateOptions(options)
  const chgOpts = (vOpts !== getPathOptions(pathGroup))
  if (!(chgOpts || chgPts)) return null // nothing to update

  if (chgOpts) {  // Update stored properties
    setAttributes(pathGroup, {
      'data-curve': vOpts.curve,
      'data-ending': vOpts.ending,
      'data-points': pArray,
      'data-style': vOpts.style,
    })
  }

  // Rebuild base path
  if (chgPts) { // re-draw path element applying style
    const basePath = buildBasePath(points, vOpts.curve)
    applyPathStyle(pathGroup, basePath, vOpts.style)
  }

  // Update or create marker
  if (vOpts.color !== pathGroup.dataset.color) {
    setAttributes(pathElement, {
      'stroke': vOpts.color,
      'opacity': vOpts.opacity
    })
    applyPathColor(pathGroup, vOpts.color)
  }
}

// internal support functions

// Add control points to path
function addControlPoints(pathGroup, points) {
  DEBUG && console.log(`addControlPoints(${pathGroup.id})`, points)
  points.forEach((point, index) => {
    const handle = createPointHandle(point, index)
    pathGroup.appendChild(handle)
  })
}

// Build base path without styling
function buildBasePath(points, curve = false) {
  DEBUG && console.log("buildBasePath:", points, curve)
  if (points.length < 2) return ""
  return curve ? buildCurvedPath(points) : buildStraightPath(points)
}

// Builds the "d" attribute for a path given its array of points and type
function buildStraightPath(points) {
  return points.map((p, i) => `${i === 0 ? "M" : "L"} ${p.x} ${p.y}`).join(" ")
}

// Build cubic or quadratic curve depending on number of points
function buildCurvedPath(points) {
  if (points.length < 2) return ""
  if (points.length === 2) return buildStraightPath(points)

  let d = `M ${points[0].x} ${points[0].y}`

  if (points.length === 3) {  // 3 points => quadratic line
    const [p0, p1, p2] = points
    return `${d} Q ${p1.x} ${p1.y} ${p2.x} ${p2.y}`
  }

  // For 4+ points: Use cubic Bézier with control points
  for (let i = 1; i < points.length - 2; i += 1) {
    const p0 = points[i]
    const p1 = points[i + 1]

    // Control points (same calculation as backend)
    const cp1x = p0.x + (p1.x - points[i - 1].x) / 4
    const cp1y = p0.y + (p1.y - points[i - 1].y) / 4
    const cp2x = p1.x - (points[i + 2]?.x - p0.x) / 4 || p1.x
    const cp2y = p1.y - (points[i + 2]?.y - p0.y) / 4 || p1.y

    d += ` C ${cp1x} ${cp1y}, ${cp2x} ${cp2y}, ${p1.x} ${p1.y}`
  }

  // Add last segment
  const last = points[points.length - 1]
  const prev = points[points.length - 2]
  const prev2 = points[points.length - 3]
  const cp1x = prev.x + (last.x - prev2.x) / 4
  const cp1y = prev.y + (last.y - prev2.y) / 4

  return `${d} S ${cp1x} ${cp1y}, ${last.x} ${last.y}`
}

function createPointHandle(point, index) {
  const handle = createSvgElement('circle')
  setAttributes(handle, {
    class: 'control-point',
    'data-index': index,
    cx: point.x,
    cy: point.y,
    r: 20,
    fill: '#ff4444',
    stroke: 'none',
    style: 'cursor: move' // Hidden by default
  })
  return handle
}

// remove control points - stoped editing a path
function removeControlPoints(pathGroup) {
  const points = pathGroup.querySelectorAll('.control-point')
  points.forEach(point => point.remove())
}

// converts an array o [x,y] pairs to svgpoints
function svgPoints(point_array) {
  const svgpoints = []
  point_array.forEach(point => { svgpoints.push({ x: point[0], y: point[1] }) })
  return svgpoints
}

// sanitize received options
function validateOptions(options) {
  DEBUG && console.log('validateOptions()', options)
  let color = '#000000'
  let opacity = 1
  const isPreview = (options.isPreview || options.isPreview === 'true')
  if (isPreview) {
    color = TEMP_COLOR
    opacity = TEMP_OPACITY
  } else {
    color = options.color || '#000000'
  }

  return {
    curve: !!options.curve,
    style: ['solid', 'dashed', 'double', 'wavy'].includes(options.style) ? options.style : 'solid',
    ending: ['arrow', 'tee', 'none'].includes(options.ending) ? options.ending : 'arrow',
    isPreview: isPreview,
    color: color,
    opacity: opacity
  }
}
