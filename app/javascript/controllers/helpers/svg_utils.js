// ✅ app/javascript/controllers/helpers/svg_utils.js
export const SVG_NS = "http://www.w3.org/2000/svg"

export function createSVGElement(tag) {
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
    el.setAttribute(key, value)
  }
}

export function getPointFromEvent(evt, svg) {
  const pt = svg.createSVGPoint()
  pt.x = evt.clientX
  pt.y = evt.clientY
  return pt.matrixTransform(svg.getScreenCTM().inverse())
}
