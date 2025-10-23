// app/javascript/helpers/svg_styles.js
import { angleBetweenPoints, averageAngles, createSvgElement, setAttributes } from "helpers/svg_utils"
const DASH_PATTERN = '20 20'
const PATH_WIDTH = 8
const MARKER_LENGTH = 10
const WAVE_AMPLITUDE = 10
const WAVE_LENGTH = 40 // Fixed wavelength in pixels

export function applyPathStyle(pathGroup, basePath, style) {
  const currentStyle = pathGroup.dataset.currentStyle
  if (currentStyle === style) return // Skip if no change

  // Clear previous styling
  const pathElement = pathGroup.querySelector('path')
  pathElement.removeAttribute('stroke-dasharray')
  setAttributes(pathElement, { 'stroke-width': PATH_WIDTH, 'fill': 'none' })

  switch (style) {
    case 'dashed':
      setAttributes(pathElement, { 'd': basePath, 'stroke-dasharray': DASH_PATTERN })
      break
    case 'double':
      createDoublePathGroup(pathElement, basePath)
      break
    case 'wavy':
      pathElement.setAttribute('d', createWavyPath(basePath))
      break
    default:  // solid
      pathElement.setAttribute('d', basePath)
      break
  }
  pathElement.dataset.currentStyle = style // Store applied style
}

function createDoublePathGroup(pathElement, basePath) {
  const offset = PATH_WIDTH
  const stroke = pathElement.getAttribute('stroke')

  // Remove any existing double paths
  const parent = pathElement.parentElement
  parent.querySelectorAll('.double-path').forEach(el => el.remove())

  // Create parallel paths
  const basePathTrimmed = trimPathEnd(basePath, MARKER_LENGTH)
  const group = createSvgElement("g")
  group.classList.add('double-path')
  group.appendChild(createParallelPath(basePathTrimmed, offset, stroke))
  group.appendChild(createParallelPath(basePathTrimmed, -offset, stroke))

  // Add parallel paths and Hide the base path
  parent.appendChild(group)

  // Make original path transparent but keep it for marker reference
  pathElement.style.stroke = 'transparent'
  pathElement.style.display = '' // Ensure it's visible
  pathElement.setAttribute('d', basePath) // Maintain original path
}

function createParallelPath(basePath, offset, stroke) {
  const pPath = createSvgElement('path')
  setAttributes(pPath, {
    'd': drawParallelPath(basePath, offset),
    'fill': 'none',
    'marker-end': 'none', // No markers on parallel paths
    'stroke': stroke,
    'stroke-width': PATH_WIDTH
  })
  return pPath
}

function drawParallelPath(basePath, offset) {
  // Create a temporary path to measure and sample points
  const tempPath = createSvgElement('path')
  tempPath.setAttribute('d', basePath)
  const totalLength = tempPath.getTotalLength()

  // If path has no length, return empty
  if (totalLength === 0) return ""

  // Calculate step size for sampling (smaller steps for better accuracy)
  const step = Math.max(1, totalLength / 100)
  const points = []

  // Sample points along the path
  for (let len = 0; len <= totalLength; len += step) {
    points.push(tempPath.getPointAtLength(len))
  }

  // Ensure last point is included
  if (points.length === 0 || points[points.length - 1].length < totalLength) {
    points.push(tempPath.getPointAtLength(totalLength))
  }

  // Calculate offset points
  const offsetPoints = []
  for (let i = 0; i < points.length; i++) {
    let { x, y } = points[i]
    let angle

    if (i === 0) {  // First point - use angle to next point
      const nextPoint = points[1]
      angle = angleBetweenPoints(x, y, nextPoint.x, nextPoint.y)
    } else if (i === points.length - 1) { // Last point - use angle from previous point
      const prevPoint = points[i - 1]
      angle = angleBetweenPoints(prevPoint.x, prevPoint.y, x, y)
    } else {  // Middle point - use bisecting angle
      const prevPoint = points[i - 1]
      const nextPoint = points[i + 1]
      const inAngle = angleBetweenPoints(prevPoint.x, prevPoint.y, x, y)
      const outAngle = angleBetweenPoints(x, y, nextPoint.x, nextPoint.y)
      angle = averageAngles(inAngle, outAngle)
    }

    // Apply perpendicular offset
    const offsetX = Math.cos(angle + Math.PI / 2) * offset
    const offsetY = Math.sin(angle + Math.PI / 2) * offset

    offsetPoints.push({
      x: x + offsetX,
      y: y + offsetY,
      type: i === 0 ? 'M' : 'L'
    })
  }

  // Build path string
  return offsetPoints.map(p => `${p.type} ${p.x} ${p.y}`).join(' ')
}

function trimPathEnd(basePath, trimLength = MARKER_LENGTH) {
  const temp = createSvgElement('path')
  temp.setAttribute('d', basePath)
  const total = temp.getTotalLength()

  if (total <= trimLength) return basePath  // very short path

  // Sample points until the near end
  const trimmedPath = []
  const step = Math.max(1, total / 100)

  for (let len = 0; len <= total - trimLength; len += step) {
    const pt = temp.getPointAtLength(len)
    trimmedPath.push({ x: pt.x, y: pt.y })
  }

  return trimmedPath.map((pt, i) =>
    `${i === 0 ? 'M' : 'L'} ${pt.x} ${pt.y}`
  ).join(' ')
}

function createWavyPath(d, amplitude = WAVE_AMPLITUDE) {
  // Create a temporary path to measure the actual geometry
  const tempPath = createSvgElement('path')
  tempPath.setAttribute('d', d)
  const totalLength = tempPath.getTotalLength()

  // If path has no length, return empty
  if (totalLength === 0) return ""

  // Calculate where the straight segment should start
  const straightStart = Math.max(0, totalLength - WAVE_LENGTH * 1.5)
  const points = []

  // Start with the first point
  const startPoint = tempPath.getPointAtLength(0)
  points.push(`M ${startPoint.x} ${startPoint.y}`)

  // Sample points along the actual path geometry
  const step = WAVE_LENGTH / 10 // Sample every 1/10 wavelength
  let currentLength = step

  while (currentLength <= totalLength) {
    const point = tempPath.getPointAtLength(currentLength)
    const nextPoint = tempPath.getPointAtLength(Math.min(currentLength + 1, totalLength))

    // Calculate tangent angle
    const angle = Math.atan2(nextPoint.y - point.y, nextPoint.x - point.x)

    // Calculate wave offset
    let waveOffset = 0
    if (currentLength < straightStart) {
      const phase = currentLength * (2 * Math.PI) / WAVE_LENGTH
      waveOffset = amplitude * Math.sin(phase)
    }

    // Calculate perpendicular offset
    const px = point.x + waveOffset * Math.cos(angle + Math.PI / 2)
    const py = point.y + waveOffset * Math.sin(angle + Math.PI / 2)

    points.push(`${px} ${py}`)
    currentLength += step
  }

  // Ensure we include the exact endpoint
  const endPoint = tempPath.getPointAtLength(totalLength)
  points.push(`${endPoint.x} ${endPoint.y}`)

  return points.join(' L ')
}