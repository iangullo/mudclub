// ✅ app/javascript/helpers/svg_utils.js
export const SVG_NS = "http://www.w3.org/2000/svg"
const DEBUG = false 

export function angleBetweenPoints(x1, y1, x2, y2) {
  return Math.atan2(y2 - y1, x2 - x1)
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

// Update createHandle to include selection styling
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

export function distance(x1, y1, x2, y2) {
  return Math.hypot(x2 - x1, y2 - y1)
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
        {attribute: labelAttr, tspan: labelSpan.textContent})
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


export function isSVGElement(el) {
  return el instanceof SVGElement && el.namespaceURI === SVG_NS
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

// transforms for visual wrapper - NOT PERSISTED
export function setVisualTransform(el, {x = 0, y = 0, scale = 1} = {}) {
  const transforms = []
  const oldTransform = el.getAttribute("transform")
  let oldX = 0, oldY = 0, oldS = 1
  if (oldTransform) {  // Get old visual transform (if any)
    const oldTranslate = oldTransform.match(/translate\(([^,]+),\s*([^)]+)\)/)
    const oldScale = oldTransform.match(/scale\(([^)]+)\)/)
    oldX = oldTranslate ? parseFloat(oldTranslate[1]) : 0
    oldY = oldTranslate ? parseFloat(oldTranslate[2]) : 0
    oldS = oldScale ? parseFloat(oldScale[1]) : 1
  }
  const newX = x !== 0 ? x : oldX
  const newY = y !== 0 ? y : oldY
  const newScale = scale !== null ? scale : oldS
  if (newX || newY) transforms.push(`translate(${newX},${newY})`)
  if (newScale !== 1) transforms.push(`scale(${newScale})`)
  el.setAttribute("transform", transforms.join(" "))
  DEBUG && console.log("applying transform: ", transforms)
}

// Prepare the outer wrapper <g> to apply visual scale only
export function wrapContent(content, x, y, scale, type) {
  const wrapper = createGroup(x, y)
  wrapper.classList.add("wrapper") // if you want to style/debug
  const id = content.getAttribute("id")
  setAttributes(wrapper, {draggable: true, id: `${id}-wrapper`, type: type})
  setVisualTransform(wrapper, {x, y, scale})
  wrapper.appendChild(content)  // copy cloned symbol inside
  DEBUG && console.log("wrapContent: ", wrapper)
  return wrapper
}
