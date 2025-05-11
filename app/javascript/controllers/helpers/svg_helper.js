// controllers/helpers/svg_helper.js
export const SVG_NS = "http://www.w3.org/2000/svg"
export const svgCache = {}
const DEBUG = true 

// --- CREATE OBJECTS ---
export function cloneSVGElement(svgElement, size) {
  if (!(svgElement instanceof SVGElement)) {
    DEBUG && console.warn("Provided element is not an SVG element.")
    return null
  }
  
  const clonedElement = svgElement.cloneNode(true)
  const fallbackSize = parseFloat(svgElement.getAttribute("width")) || 100
  const finalSize = size || fallbackSize  // Use original size if none is provided
  setSvgSize(clonedElement, finalSize)
  return clonedElement
}

/**
 * Fetches the raw SVG text at `src` (caches by URL).
 * @param {string} src – URL of the SVG asset.
 * @returns {Promise<string|null>} the SVG markup or null on error.
 */
export async function fetchSvgText(src) {
  if (svgCache[src]) return svgCache[src]

  try {
    const response = await fetch(src)
    if (!response.ok) throw new Error(`Failed to fetch SVG: ${response.status} ${response.statusText}`)
    const svgText = await response.text()
    svgCache[src] = svgText
    return svgText
  } catch (err) {
    DEBUG && console.error("fetchSvgText error:", err)
    return null
  }
}

export function parseSvg(svgText) {
  if (typeof svgText !== "string") return null
  try {
    const parser = new DOMParser()
    const doc = parser.parseFromString(svgText, "image/svg+xml")
    return doc.documentElement
  } catch (error) {
    DEBUG && console.error("Error parsing SVG:", error)
    return null
  }
}

export function updateLabel(svgElement, label) {
  const labelElement = svgElement.querySelector("tspan#label")
  if (labelElement) {
    labelElement.textContent = label
  } else {
    DEBUG && console.warn("Label not found in SVG")
  }
}

export function zoomToFit(svg, img) {
  const w = img.naturalWidth
  const h = img.naturalHeight

  if (!w || !h) {
    DEBUG && console.error("Invalid image dimensions.")
    return
  }

  const maxWidth = window.innerWidth * 0.9 // 90% of the window width
  const maxHeight = window.innerHeight * 0.75 // 75% of the window height
  
  const widthRatio = maxWidth / w
  const heightRatio = maxHeight / h
  const scale = Math.min(widthRatio, heightRatio)
  const newWidth = Math.min(w * scale, maxWidth)
  const newHeight = Math.min(h * scale, maxHeight)

  if (DEBUG) {
    console.log(`limits: ${maxWidth} x ${maxHeight}`)
    console.log(`img: ${w} x ${h}`)
    console.log("scale:", scale)
    console.log(`new container: ${newWidth} x ${newHeight}`)
  }

  svg.setAttribute("viewBox", `0 0 ${w} ${h}`)
  svg.setAttribute("width", newWidth)
  svg.setAttribute("height", newHeight)
  svg.setAttribute("preserveAspectRatio", "xMidYMid meet")
}

// --- PATH GENERATION ---
function createPathFromPoints(points, commandType) {
  let d = `${commandType}${points[0].x},${points[0].y}`
  points.slice(1).forEach(([x, y]) => { d += ` ${x},${y}` })
  return d
}

// Create a straight path with 2 points
function createStraightPath(points) {
  const pathEl = createSVGElement("path")
  const d = createPathFromPoints(points, "M")
  pathEl.setAttribute("d", d)
  return pathEl
}

// Refactor bezier creation to handle different bezier types
function createBezierPath(points) {
  if (points.length === 2) {
    return createStraightPath(points)
  } else if (points.length === 3) {
    return createQuadraticPath(points)
  } else if (points.length >= 4) {
    return createCubicPath(points)
  } else {
    DEBUG && console.error("Bezier path requires at least 2 points.")
    return null
  }
}

// Create a quadratic bezier path with 3 points
function createQuadraticPath(points) {
  const pathEl = createSVGElement("path")

  // Ensure there are exactly 3 points for a quadratic curve
  if (points.length !== 3) {
    DEBUG && console.error("Quadratic Bezier requires exactly 3 points.")
    return null
  }
  const [start, control, end] = points
  const d = `M${start.x},${start.y} Q${control.x},${control.y} ${end.x},${end.y}`

  pathEl.setAttribute("d", d)
  return pathEl
}

// Create a cubic bezier path with 4 or more points
function createCubicPath(points) {
  const pathEl = createSVGElement("path")

  // If there are less than 4 points, it cannot be a cubic bezier
  if (points.length < 4) {
    DEBUG && console.error("Cubic Bezier requires at least 4 points.")
    return null
  }

  let d = `M${points[0].x},${points[0].y}` // Starting point

  for (let i = 1; i < points.length - 2; i += 3) {
    const [cp1, cp2, end] = points.slice(i, i + 3)
    d += ` C${cp1.x},${cp1.y} ${cp2.x},${cp2.y} ${end.x},${end.y}` // Add cubic bezier
  }

  pathEl.setAttribute("d", d)
  return pathEl
}

// Helper function to parse path data (Straight or Cubic Bezier Curves only)
function parsePathData(d) {
  const pathCommands = []
  const regex = /([MLCQS])\s*([\d.,-]+)/g
  let match
  while ((match = regex.exec(d)) !== null) {
    const type = match[1]
    const points = match[2].split(",").map(Number)
    switch (type) {
      case 'M': // "M" is MoveTo, just add the starting point
        pathCommands.push({ type, points: [[points[0], points[1]]] })
        break
      case 'L': // "L" is LineTo, add a line segment
        pathCommands.push({ type, points: [[points[0], points[1]], [points[2] || points[0], points[3] || points[1]]] })
        break
      case 'C': // "C" is Cubic Bezier Curve (Control Point 1 + Control Point 2 + End Point)
        pathCommands.push({
          type,
          points: [
            [points[0], points[1]],  // Control point 1
            [points[2], points[3]],  // Control point 2
            [points[4], points[5]]   // End point
          ]
        })
        break
      case 'Q':
        pathCommands.push({
          type,
          points: [
            [points[0], points[1]],  // Control point
            [points[2], points[3]]   // End point
          ]
        })
        break        
      default:  // Unknown command
      break
    }
  }
  return pathCommands
}

function applyStrokeStyle(pathEl, options = {}) {
  const {
    style = "solid",
    stroke = "black",
    strokeWidth = 2,
    dashArray = "4 2",
    opacity = 1,
    ...rest
  } = options

  const d = pathEl.getAttribute("d")
  const resultPaths = []

  switch (style) {
    case "solid":
    case "dashed": {
      const clone = pathEl.cloneNode(false)
      clone.setAttribute("stroke", stroke)
      clone.setAttribute("stroke-width", strokeWidth)
      clone.setAttribute("fill", "none")
      clone.setAttribute("opacity", opacity)
      if (style === "dashed") {
        clone.setAttribute("stroke-dasharray", dashArray)
      } else {
        clone.removeAttribute("stroke-dasharray")
      }
      resultPaths.push(clone)
      break
    }

    case "double": {
      const [d1, d2] = generateStrokeForParallelPath(d, { stroke, strokeWidth, ...rest })
      const path1 = document.createElementNS("http://www.w3.org/2000/svg", "path")
      path1.setAttribute("d", d1)
      path1.setAttribute("stroke", stroke)
      path1.setAttribute("stroke-width", strokeWidth / 2)
      path1.setAttribute("fill", "none")
      path1.setAttribute("opacity", opacity)

      const path2 = document.createElementNS("http://www.w3.org/2000/svg", "path")
      path2.setAttribute("d", d2)
      path2.setAttribute("stroke", stroke)
      path2.setAttribute("stroke-width", strokeWidth / 2)
      path2.setAttribute("fill", "none")
      path2.setAttribute("opacity", opacity)

      resultPaths.push(path1, path2)
      break
    }

    case "wavy": {
      const wavyD = generateStrokeForWavyPath(d, { ...rest })
      const wavyPath = document.createElementNS("http://www.w3.org/2000/svg", "path")
      wavyPath.setAttribute("d", wavyD)
      wavyPath.setAttribute("stroke", stroke)
      wavyPath.setAttribute("stroke-width", strokeWidth)
      wavyPath.setAttribute("fill", "none")
      wavyPath.setAttribute("opacity", opacity)

      resultPaths.push(wavyPath)
      break
    }

    default:
      // fallback: solid clone
      const fallback = pathEl.cloneNode(false)
      fallback.setAttribute("stroke", stroke)
      fallback.setAttribute("stroke-width", strokeWidth)
      fallback.setAttribute("fill", "none")
      fallback.setAttribute("opacity", opacity)
      resultPaths.push(fallback)
      break
  }

  return resultPaths
}

// Generate two parallel strokes for a path, symmetrically displaced from the central path
function generateStrokeForParallelPath(d, options = {}) {
  const pathCommands = parsePathData(d)
  const offset = options.offset ?? 4

  let path1 = ""
  let path2 = ""

  pathCommands.forEach((command) => {
    if (command.type === "M" || command.type === "L") {
      // Handle straight lines: Same as before
      const [x1, y1] = command.points[0]
      const [x2, y2] = command.points[1]

      // Calculate the vector and perpendicular direction
      const dx = x2 - x1
      const dy = y2 - y1
      const len = Math.sqrt(dx * dx + dy * dy)
      const perpX = -dy / len
      const perpY = dx / len

      // Offset points for path1 and path2
      const offset1 = [x1 + perpX * offset, y1 + perpY * offset]
      const offset2 = [x1 - perpX * offset, y1 - perpY * offset]
      const offset3 = [x2 + perpX * offset, y2 + perpY * offset]
      const offset4 = [x2 - perpX * offset, y2 - perpY * offset]

      path1 += `M${offset1[0]},${offset1[1]} L${offset3[0]},${offset3[1]} `
      path2 += `M${offset2[0]},${offset2[1]} L${offset4[0]},${offset4[1]} `
    }
    
    // Handle Cubic Bezier Curve
    else if (command.type === "C") {
      const [cx1, cy1] = command.points[0]  // Control point 1
      const [cx2, cy2] = command.points[1]  // Control point 2
      const [x2, y2] = command.points[2]    // End point

      // We need to compute perpendicular points for the cubic curve at various intervals
      for (let t = 0; t <= 1; t += 0.1) {
        // Compute the cubic bezier point at t (using the cubic formula)
        const x = Math.pow(1 - t, 3) * command.points[0][0] + 3 * Math.pow(1 - t, 2) * t * cx1 + 3 * (1 - t) * Math.pow(t, 2) * cx2 + Math.pow(t, 3) * x2
        const y = Math.pow(1 - t, 3) * command.points[0][1] + 3 * Math.pow(1 - t, 2) * t * cy1 + 3 * (1 - t) * Math.pow(t, 2) * cy2 + Math.pow(t, 3) * y2

        // Calculate the vector and perpendicular direction
        const dx = cx2 - cx1
        const dy = cy2 - cy1
        const len = Math.sqrt(dx * dx + dy * dy)
        const perpX = -dy / len
        const perpY = dx / len

        // Apply the perpendicular offset
        const offset1 = [x + perpX * offset, y + perpY * offset]
        const offset2 = [x - perpX * offset, y - perpY * offset]

        if (t === 0) {
          path1 += `M${offset1[0]},${offset1[1]} `
          path2 += `M${offset2[0]},${offset2[1]} `
        } else {
          path1 += `L${offset1[0]},${offset1[1]} `
          path2 += `L${offset2[0]},${offset2[1]} `
        }
      }
    }
  })

  return [path1, path2]
}

// Generate a wavy stroke for a path, following the curve of the path itself
function generateStrokeForWavyPath(d, options = {}) {
  const pathCommands = parsePathData(d)
  const amplitude = options.amplitude ?? 4
  const frequency = options.frequency ?? 2

  let path = ""

  pathCommands.forEach((command) => {
    if (command.type === "M" || command.type === "L") {
      // Handle straight lines: Use sine wave offset along the path
      const [x1, y1] = command.points[0]
      const [x2, y2] = command.points[1]

      // Number of points between the start and end of the path
      const steps = Math.max(Math.floor(Math.sqrt((x2 - x1) ** 2 + (y2 - y1) ** 2) / 10), 5)
      for (let i = 0; i <= steps; i++) {
        const t = i / steps
        const x = (1 - t) * x1 + t * x2
        const y = (1 - t) * y1 + t * y2
        const offsetX = amplitude * Math.sin(frequency * t * Math.PI * 2)
        
        // Apply wavy offset and append to path
        path += `${i === 0 ? 'M' : 'L'}${x + offsetX},${y} `
      }
    }

    // Handle Cubic Bezier Curve
    else if (command.type === "C") {
      const [cx1, cy1] = command.points[0]  // Control point 1
      const [cx2, cy2] = command.points[1]  // Control point 2
      const [x2, y2] = command.points[2]    // End point

      // Generate wavy effect along the cubic curve
      for (let t = 0; t <= 1; t += 0.1) {
        const x = Math.pow(1 - t, 3) * command.points[0][0] + 3 * Math.pow(1 - t, 2) * t * cx1 + 3 * (1 - t) * Math.pow(t, 2) * cx2 + Math.pow(t, 3) * x2
        const y = Math.pow(1 - t, 3) * command.points[0][1] + 3 * Math.pow(1 - t, 2) * t * cy1 + 3 * (1 - t) * Math.pow(t, 2) * cy2 + Math.pow(t, 3) * y2

        const offsetX = amplitude * Math.sin(frequency * t * Math.PI * 2)
        
        // Apply wavy offset and append to path
        path += `${t === 0 ? 'M' : 'L'}${x + offsetX},${y} `
      }
    }
  })

  return path
}

// "arrow" or "tee" termination for a path
export function appendEndingToPath(pathEl, options = {}, svgRoot = null) {
  const { ending = null, stroke = "black", strokeWidth = 2 } = options

  if (!ending || !pathEl || !svgRoot) return

  // Create a unique marker ID
  const markerId = `marker-${ending}-${Math.random().toString(36).substr(2, 6)}`

  const marker = document.createElementNS("http://www.w3.org/2000/svg", "marker")
  marker.setAttribute("id", markerId)
  marker.setAttribute("markerWidth", "10")
  marker.setAttribute("markerHeight", "10")
  marker.setAttribute("refX", "5")
  marker.setAttribute("refY", "5")
  marker.setAttribute("orient", "auto")
  marker.setAttribute("markerUnits", "strokeWidth")

  const path = document.createElementNS("http://www.w3.org/2000/svg", "path")
  path.setAttribute("fill", stroke)

  if (ending === "arrow") {
    path.setAttribute("d", "M 0 0 L 10 5 L 0 10 z") // Simple triangle arrow
  } else if (ending === "tee") {
    path.setAttribute("d", "M 0 0 L 10 0") // Horizontal line
  }

  marker.appendChild(path)
  svgRoot.querySelector("defs")?.appendChild(marker)

  pathEl.setAttribute("marker-end", `url(#${markerId})`)
}

export function updatePath(group, points = [], options = {}) {
  const {
    type = "bezier",
    ending = null,
    svgRoot = null,
  } = options

  if (!group || points.length < 1) {
    DEBUG && console.error("Invalid arguments to updatePath.")
    return
  }

  // Clear all previous children
  group.innerHTML = ""

  // Step 1: Create base path geometry
  const pathFunctions = { straight: createStraightPath, bezier: createBezierPath }
  const basePath = (pathFunctions[type] || createBezierPath)(points)

  if (!basePath) {
    DEBUG && console.error("Could not create base path.")
    return
  }

  // Step 2: Apply stroke style
  const visualPaths = applyStrokeStyle(basePath, options) || []

  // Step 3: Append all visual paths to the group
  visualPaths.forEach(p => group.appendChild(p))

  // Step 4: Optionally append an ending (like arrow)
  if (ending && visualPaths.length > 0) {
    appendEndingToPath(visualPaths[visualPaths.length - 1], options, svgRoot)
  }
}

// --- TRANSFORMS ---
function setSvgSize(svgElement, size, center = true) {
  svgElement.setAttribute("width", size)
  svgElement.setAttribute("height", size)
  if (center) {
    svgElement.setAttribute("x", -size / 2)
    svgElement.setAttribute("y", -size / 2)
  }
}

// --- SERIALIZATION ---
export function serializeGroup(gEl) {
  if (!(gEl instanceof SVGGElement)) {
    DEBUG && console.warn("serializeGroup expects an SVG <g> element.")
    return null
  }

  const type = gEl.dataset.type
  const transform = gEl.getAttribute("transform") || null
  const { x, y } = getTransformCoords(transform)

  if (type === "path") {
    const path = gEl.querySelector("path")
    if (!path) return null
    return {
      type: path.dataset.type || "bezier",
      points: JSON.parse(path.dataset.points || "[]"),
      style: path.dataset.style || "solid",
      stroke: path.dataset.stroke || "black",
      ending: path.dataset.ending || null,
      x,
      y,
      transform
    }
  }

  if (type === "object") {
    return {
      type: "object",
      role: gEl.dataset.role || null,
      label: gEl.dataset.label || null,
      x,
      y,
      transform, // Include transform for object as well
      content: gEl.innerHTML // Preserve full SVG contents
    }
  }

  return null
}

export function deserializeGroup(data, svgRoot) {
  const g = createGroup(data.x, data.y)
  if (data.type === "object") {
    g.dataset.type = "object"
    g.dataset.role = data.role || null
    g.dataset.label = data.label || null
    g.setAttribute("transform", data.transform || "")  // Apply transform to the group
    g.innerHTML = data.content || ""
    return g
  } else if (["straight", "bezier"].includes(data.type)) {
    const options = {
      type: data.type,
      style: data.style,
      stroke: data.stroke,
      ending: data.ending,
      svgRoot: svgRoot
    }
    updatePath(g, data.points, options)
    g.setAttribute("transform", data.transform || "")
    return g
  }
  return null
}

// --- UTILS ---
export function createGroup(x, y) {
  const group = createSVGElement("g", { transform: `translate(${x}, ${y})` })
  group.classList.add("draggable")
  group.style.cursor = "grab"
  return group
}

// Helper function to create a handle element
export function createHandle(pt, index) {
  const handle = createSVGElement('circle')  // Create a circle as the handle
  handle.setAttribute('cx', pt.x)  // Set the x position based on the point
  handle.setAttribute('cy', pt.y)  // Set the y position based on the point
  handle.setAttribute('r', 5)  // Set the radius for the handle
  handle.setAttribute('fill', 'red')  // Color of the handle
  handle.setAttribute('class', 'handle draggable')  // Add class for styling and dragging
  handle.dataset.pointIndex = index  // Store the index of the point on the handle
  return handle
}

export function createSVGElement(tag, attrs = {}) {
  const el = document.createElementNS(SVG_NS, tag)
  Object.entries(attrs).forEach(([k, v]) => el.setAttribute(k, v))
  return el
}

function getTransformCoords(transformStr) {
  const match = transformStr?.match(/translate\(([^,]+),\s*([^)]+)\)/)
  return {
    x: parseFloat(match?.[1]) || 0,
    y: parseFloat(match?.[2]) || 0
  }
}

export function toSvgPoint(evt, canvas) {
  const p = canvas.createSVGPoint()
  p.x = evt.clientX
  p.y = evt.clientY
  return p.matrixTransform(canvas.getScreenCTM().inverse())
}
