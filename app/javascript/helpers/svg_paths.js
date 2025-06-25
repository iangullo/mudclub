// app/javascript/helpers/svg_paths.js
import { createSvgElement, wrapContent } from "helpers/svg_utils"
import { PATH_WIDTH, applyStrokeStyle } from "helpers/svg_strokes"
import { applyMarker } from "helpers/svg_markers"

const TEMP_COLOR = '#888888'
const TEMP_OPACITY = 0.5
const MIN_POINTS_FOR_CURVE = 3
const DEBUG = false


export function buildPathD(points, curve = false) {
  if (points.length === 0) return ""
  if (curve) {
    return buildCurvedPath(points)
  } else {
    return buildStraightPath(points)
  }
}

export function createPath(points = [], options = {}) {
  // Validate options
  const validatedOptions = {
    curve: !!options.curve,
    style: ['solid', 'dashed', 'double', 'wavy'].includes(options.style) ? options.style : 'solid',
    ending: ['arrow', 'tee'].includes(options.ending) ? options.ending : 'none',
    color: options.color || '#000000',
    scale: options.scale || 1
  }

  // Create path element
  const pathElement = createSvgElement('path')
  pathElement.setAttribute('stroke-width', PATH_WIDTH)
  pathElement.setAttribute('fill', 'none')
  pathElement.dataset.color  = color
  pathElement.dataset.curve  = validatedOptions.curve.toString()
  pathElement.dataset.style  = validatedOptions.style
  pathElement.dataset.ending = validatedOptions.ending

  // Create wrapper group
  const pathGroup = createSvgElement('g')
  pathGroup.classList.add('path-line')
  pathGroup.dataset.type = 'path'
  pathGroup.appendChild(pathElement)

  // Store original points in dataset (like symbol coordinates)
  pathGroup.dataset.points = JSON.stringify(points)
  pathGroup.dataset.curve = options.curve ? 'true' : 'false'
  pathGroup.dataset.style = options.style || 'solid'
  pathGroup.dataset.ending = options.ending || 'arrow'
  
  // Initial positioning (similar to symbol positioning)
  const firstPoint = points[0] || { x: 0, y: 0 }
  const transform = {
    x: firstPoint.x,
    y: firstPoint.y,
    scale: options.scale || 1
  }

  // Apply initial styling
  updatePath(pathElement, points, {
    ...options,
    isPreview: options.isPreview || false
  })

  pathGroup.appendChild(pathElement)

  /// Return wrapped content (identical to symbol approach)
  return {
    element: wrapContent(pathGroup, transform.x, transform.y, transform.scale),
    update: (newPoints, updateOpts) => {
      pathGroup.dataset.points = JSON.stringify(newPoints)
      return updatePath(pathElement, newPoints, {
        ...options,
        ...updateOpts
      })
    },
    finalize: () => {
      pathElement.setAttribute('stroke', options.color || '#000')
      pathElement.setAttribute('opacity', '1')
      return pathGroup
    }
  }
}

export function updatePath(pathElement, points, options) {
  if (!pathElement || points.length < 2) {
    pathElement?.setAttribute('d', '')
    return
  }

  // Apply transform through wrapper (like symbol transform)
  const wrapper = pathElement.parentNode
  if (wrapper && points.length > 0) {
    const firstPoint = points[0]
    wrapper.setAttribute('transform', `translate(${firstPoint.x}, ${firstPoint.y}) scale(${options.scale || 1})`)
  }
  
  const pathData = buildPathD(points, options.curve)
  pathElement.setAttribute('d', pathData)
  
  // Apply styling (identical to symbol styling approach)
  pathElement.setAttribute('stroke', options.isPreview ? TEMP_COLOR : options.color || '#000')
  pathElement.setAttribute('opacity', options.isPreview ? TEMP_OPACITY : '1')
  applyStrokeStyle(pathElement, options)
  applyMarker(pathElement, options.ending)
}

export function validatePath(data) {
  return data && 
    data.type === 'path' &&
    Array.isArray(data.points) &&
    data.points.every(p => typeof p.x === 'number' && typeof p.y === 'number') &&
    typeof data.style === 'string' &&
    typeof data.color === 'string' &&
    typeof data.ending === 'string'
}

// Builds the "d" attribute for a path given its array of points and type
function buildStraightPath(points) {
  if (points.length === 0) return ""
  return points.map((p, i) => `${i === 0 ? "M" : "L"} ${p.x} ${p.y}`).join(" ")
}

// Build cubic or quadratic curve depending on number of points
function buildCurvedPath(points) {
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
