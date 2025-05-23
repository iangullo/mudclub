// ✅ app/javascript/controllers/helpers/svg_paths.js
import { createSVGElement } from "./svg_utils.js"
import { applyStrokeStyle } from "./svg_strokes.js"

// Builds the "d" attribute for a path given its array of points and type
export function buildPathD(points, { curved = false } = {}) {
  if (points.length === 0) return ""
  if (curved) {
    return buildSmoothCurveD(points)
  } else {
    return points.map((p, i) => `${i === 0 ? "M" : "L"} ${p.x} ${p.y}`).join(" ")
  }
}

// Build cubic or quadratic curve depending on number of points
export function buildSmoothCurveD(points) {
  if (points.length < 2) return ""

  if (points.length === 2) {
    // línea recta
    return `M ${points[0].x} ${points[0].y} L ${points[1].x} ${points[1].y}`
  } else if (points.length === 3) {
    // quadratic line
    const [p0, p1, p2] = points
    return `M ${p0.x} ${p0.y} Q ${p1.x} ${p1.y} ${p2.x} ${p2.y}`
  } else {
    // Cubic curve
    for (let i = 1; i + 2 < rest.length; i += 3) {
      const [cp1, cp2, p] = rest.slice(i - 1, i + 2)
      d += ` C ${cp1.x} ${cp1.y}, ${cp2.x} ${cp2.y}, ${p.x} ${p.y}`
    }
    // Optional fallback for leftover points
    const leftover = rest.length % 3
    if (leftover === 1) {
      const last = rest.at(-1)
      d += ` L ${last.x} ${last.y}`
    } else if (leftover === 2) {
      const [cp, end] = rest.slice(-2)
      d += ` Q ${cp.x} ${cp.y}, ${end.x} ${end.y}`
    }    
    return d
  }
}

// Extract points (as array of { x, y }) from a "d" attribute
export function getPointsFromPath(pathElement) {
  const d = pathElement.getAttribute("d")
  const segments = d.match(/[MLCQ][^MLCQ]+/g) || []
  return segments.map(seg => {
    const nums = seg.match(/[-\d.]+/g).map(Number)
    return { x: nums.at(-2), y: nums.at(-1) }
  })
}

// Creates a new path applying the correct style
export function createPath(points, options = {}) {
  const {
    curved = false,
    strokeStyle = "solid",
    strokeWidth = 2,
    strokeColor = "black"
  } = options

  const path = createSVGElement("path")
  path.setAttribute("d", buildPathD(points, { curved }))
  applyStrokeStyle(path, { strokeStyle, strokeWidth, strokeColor })

  path.dataset.points = JSON.stringify(points)
  return path
}

// update an existing SVG path, with new "d" & styling
export function updatePath(pathElement, points, options = {}, append = false) {
  const currentPoints = JSON.parse(pathElement.dataset.points || "[]")
  const newPoints = append ? [...currentPoints, ...points] : points

  pathElement.setAttribute("d", buildPathD(newPoints, { curved: options.curved }))
  applyStrokeStyle(pathElement, { ...options })

  pathElement.dataset.points = JSON.stringify(newPoints)
  pathElement.dataset.curved = options.curved ? "true" : "false"

  return pathElement
}

function extractTermination(pathElement) {
  const marker = pathElement.getAttribute("marker-end")
  if (!marker) return "none"
  if (marker.includes("arrowhead")) return "arrow"
  if (marker.includes("terminator-T")) return "T"
  return "none"
}

// SERIALIZE data from a path to save as JSON
export function serializePath(pathElement) {
  const points = JSON.parse(pathElement.dataset.points || "[]")
  const curved = pathElement.dataset.curved === "true"

  return {
    type: "path",
    points,
    curved,
    strokeStyle: pathElement.dataset.strokeStyle || "solid",
    strokeWidth: parseFloat(pathElement.getAttribute("stroke-width")) || 2,
    strokeColor: pathElement.getAttribute("stroke") || "black",
    termination: extractTermination(pathElement),
  }
}

export function deserializePath(data) {
  const path = createSVGElement("path")
  path.dataset.points = JSON.stringify(data.points)
  path.dataset.curved = data.curved ? "true" : "false"
  path.dataset.strokeStyle = data.strokeStyle

  path.setAttribute("d", buildPathD(data.points, { curved: data.curved }))
  applyStrokeStyle(path, {
    strokeStyle: data.strokeStyle,
    strokeWidth: data.strokeWidth,
    strokeColor: data.strokeColor,
    termination: data.termination
  })

  return path
}
