// ✅ app/javascript/controllers/helpers/svg_utils.js
export const SVG_NS = "http://www.w3.org/2000/svg"
const DEBUG = true 

export function createSvgElement(tag) {
  if (typeof tag !== "string") throw new TypeError("Expected tag to be a string")
  return document.createElementNS(SVG_NS, tag)
}

export function createGroup(x = 0, y = 0) {
  const group = createSvgElement("g")
  group.classList.add("draggable")
  group.setAttribute("draggable", "true")
  return group
}

export function distance(x1, y1, x2, y2) {
  return Math.hypot(x2 - x1, y2 - y1)
}

export function angleBetweenPoints(x1, y1, x2, y2) {
  return Math.atan2(y2 - y1, x2 - x1)
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

export function getInnerElement(wrapper) {
  if (!wrapper) return null
  
  // Get the inner <g draggable> element
  const group = wrapper.querySelector('g.draggable')
  if (group) return group
    
  return null
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

export function generateId(prefix = "obj") {
  const rand = crypto.getRandomValues(new Uint32Array(2))
  return `${prefix}-${rand[0].toString(16)}${rand[1].toString(16)}`
}
