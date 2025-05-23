// ✅ app/javascript/controllers/helpers/svg_strokes.js
import { distance, angleBetweenPoints } from "./svg_utils.js"

// 🔧 Extracts SVG command segments from a path string
function parsePathData(d) {
  return d.match(/[MLCQ][^MLCQ]+/g) || []
}

// 🔧 Extracts point coordinates from a command segment
function extractPoint(segment) {
  const nums = segment.match(/[-\d.]+/g).map(Number)
  return { x: nums[0], y: nums[1] }
}

// ✅ Creates a parallel offset path (basic approximation)
function applyDoubleStroke(d, options = {}) {
  const offset = options.offset || 4
  const segments = parsePathData(d)
  const result = []

  segments.forEach(seg => {
    const { x, y } = extractPoint(seg)
    result.push(`${seg[0]} ${x + offset} ${y + offset}`)
  })

  return result.join(" ")
}

// ✅ Applies a sinusoidal stroke with flat start and end
function applyWavyStroke(d, amplitude = 4, step = 10, flatLength = 8) {
  const segments = parsePathData(d)
  const points = segments.map(extractPoint)
  if (points.length < 2) return d

  const waveD = []

  for (let i = 0; i < points.length - 1; i++) {
    const p1 = points[i]
    const p2 = points[i + 1]
    const dx = p2.x - p1.x
    const dy = p2.y - p1.y
    const dist = distance(p1.x, p1.y, p2.x, p2.y)
    const angle = angleBetweenPoints(p1.x, p1.y, p2.x, p2.y)

    for (let j = 0; j < dist; j += step) {
      const t = j / dist
      const baseX = p1.x + dx * t
      const baseY = p1.y + dy * t

      // Use sinusoidal offset except near the start/end
      let offset = 0
      if (j > flatLength && j < dist - flatLength) {
        offset = amplitude * Math.sin(t * Math.PI * 2)
      }

      const normalAngle = angle + Math.PI / 2
      const x = baseX + offset * Math.cos(normalAngle)
      const y = baseY + offset * Math.sin(normalAngle)

      waveD.push(`${j === 0 ? "M" : "L"} ${x.toFixed(2)} ${y.toFixed(2)}`)
    }
  }

  return waveD.join(" ")
}

// ✅ Appends a marker (e.g. arrowhead or T) to a path
function applyTermination(path, type = "arrow") {
  switch (type) {
    case "arrow":
      path.setAttribute("marker-end", "url(#arrowhead)")
      break
    case "T":
      path.setAttribute("marker-end", "url(#terminator-T)")
      break
    case "none":
    default:
      path.removeAttribute("marker-end")
      break
  }
}

// ✅ Applies a visual style to a given SVG path element
export function applyStrokeStyle(path, options = {}) {
  const {
    strokeStyle = "solid",
    strokeWidth = 2,
    strokeColor = "black",
    termination = "arrow"
  } = options

  path.setAttribute("stroke", strokeColor)
  path.setAttribute("fill", "none")
  path.setAttribute("stroke-width", strokeWidth)

  const originalD = path.getAttribute("d")

  switch (strokeStyle) {
    case "dashed":
      path.setAttribute("stroke-dasharray", "4 2")
      break

    case "double":
      path.setAttribute("d", applyDoubleStroke(originalD, {
        offset: strokeWidth * 1.5
      }))
      break

    case "wavy":
      path.setAttribute("d", applyWavyStroke(originalD, strokeWidth * 1.5))
      break

    case "solid":
    default:
      // No path alteration
      break
  }

  applyTermination(path, termination)
}
