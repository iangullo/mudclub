// ✅ app/javascript/controllers/helpers/svg_utils.js
export const SVG_NS = "http://www.w3.org/2000/svg"

export function createSVGElement(tag) {
  if (typeof tag !== "string") throw new TypeError("Expected tag to be a string")
  return document.createElementNS(SVG_NS, tag)
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

export function getPointFromEvent(evt, svg) {
  const pt = svg.createSVGPoint()
  pt.x = evt.clientX
  pt.y = evt.clientY
  const ctm = svg.getScreenCTM()
  return ctm ? pt.matrixTransform(ctm.inverse()) : { x: 0, y: 0 }
}
