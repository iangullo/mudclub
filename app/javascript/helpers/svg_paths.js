// app/javascript/helpers/svg_paths.js
import { createGroup, createSvgElement, generateId, isSVGElement, setAttributes, wrapContent } from "helpers/svg_utils"
import { applyPathStyle } from "helpers/svg_styles"
import { applyMarkerColor, createMarker } from "helpers/svg_markers"

export const MIN_POINTS_FOR_CURVE = 3
const TEMP_COLOR = '#888888'
const TEMP_OPACITY = 0.5
const DEBUG = false

export function applyPathColor(pathElement, color) {
  pathElement.setAttribute('color', color)
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
  const inner = getInnerGroup(pathElement) || pathElement
  const pointsData = inner.getAttribute('data-points')

  if (!pointsData) return []

  try {
    return JSON.parse(pointsData).map(([x, y]) => ({ x, y }))
  } catch (e) {
    console.error('Error parsing path points:', e)
    return []
  }
}

export function hideControlPoints(pathElement) {
  const controlPoints = pathElement.querySelector('.control-points')
  if (controlPoints) {
    controlPoints.style.display = 'none'
  }
}

export function showControlPoints(pathElement) {
  const controlPoints = pathElement.querySelector('.control-points')
  if (controlPoints) {
    controlPoints.style.display = 'block'
  }
}

export function updateControlPointsPosition(pathElement, points) {
  const controlPoints = pathElement.querySelectorAll('.control-point')
  controlPoints.forEach((controlPoint, index) => {
    if (index < points.length) {
      const point = points[index]
      const circle = controlPoint.querySelector('.control-point-handle')
      const hitArea = controlPoint.querySelector('.control-point-hit-area')
      const text = controlPoint.querySelector('.control-point-index')

      if (circle) circle.setAttribute('cx', point.x)
      if (circle) circle.setAttribute('cy', point.y)
      if (hitArea) hitArea.setAttribute('cx', point.x)
      if (hitArea) hitArea.setAttribute('cy', point.y)
      if (text) text.setAttribute('x', point.x)
      if (text) text.setAttribute('y', point.y - 15)
    }
  })
}

export function updatePath(pathGroup, points, options) {
  if (!isSVGElement(pathGroup)) return null
  const pArray = points.map(p => [p.x, p.y])
  const pathElement = pathGroup.querySelector('path')
  const vOpts = validateOptions(options)

  if (DEBUG) {
    console.log("updatePath ", pathGroup)
    console.log("options: ", vOpts)
    console.log("points: ", points)
  }

  // Update stored properties
  setAttributes(pathGroup, {
    'data-curve': vOpts.curve,
    'data-ending': vOpts.ending,
    'data-isPreview': vOpts.isPreview,
    'data-points': JSON.stringify(pArray),
    'data-style': vOpts.style,
  })

  setAttributes(pathElement, {
    'stroke': vOpts.color,
    'opacity': vOpts.opacity
  })

  // Rebuild base path
  const basePath = buildBasePath(points, vOpts.curve)

  // Apply style-specific modifications
  applyPathStyle(pathElement, basePath, vOpts.style)

  // Update or create marker
  applyPathColor(pathGroup, vOpts.color)
}

// internal support functions

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

// converts an array o [x,y] pairs to svgpoints
function svgPoints(point_array) {
  const svgpoints = []
  point_array.forEach(point => { svgpoints.push({ x: point[0], y: point[1] }) })
  return svgpoints
}

// sanitize received options
function validateOptions(options) {
  const isPreview = options.isPreview || false
  const color = isPreview ? TEMP_COLOR : (options.color || '#000000')
  const opacity = isPreview ? TEMP_OPACITY : 1

  return {
    curve: !!options.curve,
    style: ['solid', 'dashed', 'double', 'wavy'].includes(options.style) ? options.style : 'solid',
    ending: ['arrow', 'tee', 'none'].includes(options.ending) ? options.ending : 'arrow',
    isPreview: isPreview,
    color: color,
    opacity: opacity
  }
}
