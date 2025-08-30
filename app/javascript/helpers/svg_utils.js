// ✅ app/javascript/helpers/svg_utils.js
export const SVG_NS = "http://www.w3.org/2000/svg"
const EPSILON = 0.01
const SELECTION_TOLERANCE = 0
const DEBUG = false

export function angleBetweenPoints(x1, y1, x2, y2) {
  return Math.atan2(y2 - y1, x2 - x1)
}

export function averageAngles(a1, a2) {
  return Math.atan2(Math.sin(a1) + Math.sin(a2), Math.cos(a1) + Math.cos(a2))
}

export function cssColorToHex(color) {
  if (!color) return '#000000'

  // If already hex format (3, 4, 6, or 8 digits)
  if (/^#([0-9a-f]{3,4}|[0-9a-f]{6}|[0-9a-f]{8})$/i.test(color)) {
    return color.toLowerCase() // normalize case
  }

  // Handle CSS variables and color names
  const div = document.createElement('div')
  div.style.color = color
  document.body.appendChild(div)

  try {
    const computed = window.getComputedStyle(div).color
    const rgbMatch = computed.match(/^rgba?\((\d+),\s*(\d+),\s*(\d+)/)

    if (rgbMatch) {
      const r = parseInt(rgbMatch[1]).toString(16).padStart(2, '0')
      const g = parseInt(rgbMatch[2]).toString(16).padStart(2, '0')
      const b = parseInt(rgbMatch[3]).toString(16).padStart(2, '0')
      return `#${r}${g}${b}`
    }
  } catch (e) {
    console.warn('Could not convert color:', color, e)
  } finally {
    document.body.removeChild(div)
  }

  return '#000000' // Fallback
}

export function createGroup(x = 0, y = 0) {
  return createSvgElement("g")
}

export function createHandle(point, index) {
  const handle = createSvgElement('circle')
  setAttributes(handle, {
    class: 'handle selection-indicator',
    'data-point-index': index,
    cx: point.x,
    cy: point.y,
    r: 6,
    fill: 'white',
    stroke: 'red',
    'stroke-width': 2
  })
  return handle
}

export function createSvgElement(tag) {
  if (typeof tag !== "string") throw new TypeError("Expected tag to be a string")
  return document.createElementNS(SVG_NS, tag)
}

// distance between 2 SVG points
export function distance(x1, y1, x2, y2) {
  return Math.hypot(x2 - x1, y2 - y1)
}

// geometry helper method
export function distanceToBBox(point, bbox) {
  // Calculate closest point on bbox to the click point
  const closestX = Math.max(bbox.x, Math.min(point.x, bbox.x + bbox.width))
  const closestY = Math.max(bbox.y, Math.min(point.y, bbox.y + bbox.height))

  // Calculate distance to closest point
  const dx = point.x - closestX
  const dy = point.y - closestY

  return Math.sqrt(dx * dx + dy * dy)
}

export function findElementNearPoint(diagram, point) {
  // Get all selectable elements
  const elements = Array.from(diagram.querySelectorAll('g.wrapper'))
  let closestElement = null
  let closestDistance = Infinity

  elements.forEach(el => {
    let bbox = el.getBBox()
    let distance = distanceToBBox(point, bbox)

    if (distance < closestDistance && distance <= SELECTION_TOLERANCE) {
      closestDistance = distance
      closestElement = el
    }
  })

  return closestElement
}

export function generateId(prefix = "sym") {
  const rand = crypto.getRandomValues(new Uint32Array(2))
  return `${prefix}-${rand[0].toString(16)}${rand[1].toString(16)}`
}

export function getInnerElement(wrapper) {
  if (!wrapper) return null

  // Get the inner <g> element
  const group = wrapper.querySelector('g')
  if (group) return group

  return null
}

// 🔍 Get label content consistently with setLabel behavior
export function getLabel(el) {
  if (!el) return null

  // First check the attribute (primary storage)
  const labelAttr = el.getAttribute("label")
  if (labelAttr !== null) {
    // Verify tspan matches if exists (debug only)
    const labelSpan = el.querySelector('tspan[id^="label"]')
    if (DEBUG && labelSpan && labelSpan.textContent !== labelAttr) {
      console.warn(`Label mismatch in ${el.id}:`,
        { attribute: labelAttr, tspan: labelSpan.textContent })
    }
    return labelAttr
  }

  // Fallback to tspan content (legacy support)
  const labelSpan = el.querySelector('tspan[id^="label"]')
  return labelSpan?.textContent || null
}

export function getPointFromEvent(evt, svg) {
  const pt = svg.createSVGPoint()
  pt.x = evt.clientX
  pt.y = evt.clientY
  const ctm = svg.getScreenCTM()
  return ctm ? pt.matrixTransform(ctm.inverse()) : { x: 0, y: 0 }
}

export function getSvgScale(svg) {
  const vb = svg.viewBox.baseVal
  const renderedWidth = svg.clientWidth
  const renderedHeight = svg.clientHeight

  if (!vb || !renderedWidth || !renderedHeight) return 1

  const scaleX = renderedWidth / vb.width
  const scaleY = renderedHeight / vb.height

  // Use the smaller of the two to preserve aspect ratio and avoid cropping
  return Math.min(scaleX, scaleY)
}

// viewbox of an element
export function getViewBox(el) {
  const vb = el.viewBox.baseVal
  return { width: vb.width, height: vb.height }
}

export function highlightElement(el) {
  if (el.tagName === 'path') {
    // Store original styles
    if (!el.dataset.originalStroke) el.dataset.originalStroke = el.style.stroke || ''
    if (!el.dataset.originalStrokeWidth) el.dataset.originalStrokeWidth = el.style.strokeWidth || ''
    if (!el.dataset.originalFill) el.dataset.originalFill = el.style.fill || ''
    el.style.stroke = 'red' // Apply selection styles
    el.style.strokeWidth = '4px'
    el.style.fill = 'rgba(255, 0, 0, 0.2)'
  } else if (el.tagName === 'g') {  // Store original filter/fill
    if (!el.dataset.originalFilter) el.dataset.originalFilter = el.style.filter || ''
    if (!el.dataset.originalFill) el.dataset.originalFill = el.style.fill || ''
    el.style.filter = 'drop-shadow(0 0 10px rgba(255, 0, 0, 0.5))'
    el.style.fill = 'rgba(255, 0, 0, 0.2)'
  }
}

export function isSVGElement(el) {
  return el instanceof SVGElement && el.namespaceURI === SVG_NS
}

export function lowlightElement(el) {
  if (el.tagName === 'path') {
    el.style.stroke = el.dataset.originalStroke || ''
    el.style.strokeWidth = el.dataset.originalStrokeWidth || ''
    el.style.fill = el.dataset.originalFill || ''
    delete el.dataset.originalStroke
    delete el.dataset.originalStrokeWidth
    delete el.dataset.originalFill
  } else if (el.tagName === 'g') {
    el.style.filter = el.dataset.originalFilter || ''
    el.style.fill = el.dataset.originalFill || ''
    delete el.dataset.originalFilter
    delete el.dataset.originalFill
  }
}

export function setAttributes(el, attrs = {}) {
  for (const [key, value] of Object.entries(attrs)) {
    if (value !== null && value !== undefined) {
      el.setAttribute(key, value)
    }
  }
}

// 🔁 Update label content if present
export function setLabel(el, label) {
  if (label !== null) {
    const labelSpan = el.querySelector('tspan[id^="label"]')
    if (labelSpan) {
      el.setAttribute("label", label)
      labelSpan.textContent = label
    } else {
      DEBUG && console.warn(`Could not fine a <tspan id="label">`)
    }
  }
}

// transforms for element that should be persisted
export function setLogicalTransform(el, transform) {
  if (transform) el.setAttribute("transform", transform)
  else el.removeAttribute("transform")
}

// updates element position
export function updatePosition(el, x = 0, y = 0) {
  DEBUG && console.log("updatePosition(el:", el.id, ", x:", x, ", y:", y, ")")
  const oldTransform = el.getAttribute("transform") || ""

  let oldX = 0, oldY = 0
  let updated = false

  const newTransform = oldTransform.replace(/translate\(([^,]+),\s*([^)]+)\)/, (_, xMatch, yMatch) => {
    oldX = parseFloat(xMatch)
    oldY = parseFloat(yMatch)
    updated = true

    // Idempotency check
    if (Math.abs(oldX - x) < EPSILON && Math.abs(oldY - y) < EPSILON) {
      DEBUG && console.log("Position unchanged, skipping.")
      return `translate(${oldX},${oldY})` // unchanged
    }

    setAttributes(el, { 'data-x': x, 'data-y': y })
    return `translate(${x},${y})`
  })

  let transformOut = newTransform

  if (!updated) {
    // No existing translate, so we append it
    setAttributes(el, { 'data-x': x, 'data-y': y })
    transformOut = `translate(${x},${y}) ${oldTransform}`.trim()
  }

  el.setAttribute("transform", transformOut)
  DEBUG && console.log("applied transform:", transformOut)
}

// Prepare the outer wrapper <g> to apply visual scale only
export function wrapContent(content, type, x = 0, y = 0, draggable = true) {
  DEBUG && console.log("wrapContent(type:", type, ")")
  const wrapper = createGroup(x, y)
  wrapper.classList.add("wrapper") // if you want to style/debug
  const id = content.getAttribute("id")
  setAttributes(wrapper, { draggable: draggable, id: `${id}-wrapper`, type: type })
  wrapper.appendChild(content)  // copy cloned symbol inside
  DEBUG && console.log("wrapContent: ", wrapper)
  return wrapper
}
