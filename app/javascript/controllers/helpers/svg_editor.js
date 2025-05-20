// ✅ app/javascript/controllers/helpers/svg_editor.js
import { createSVGElement } from "./svg_utils"

export function createPathFromPoints(points, commandType = "M") {
  return points.map((pt, idx) => {
    const cmd = idx === 0 ? commandType : "L"
    return `${cmd} ${pt.x} ${pt.y}`
  }).join(" ")
}

export function createStraightPath(points) {
  return createPathFromPoints(points, "M")
}

export function createQuadraticPath(points) {
  if (points.length !== 3) throw new Error("Quadratic path requires 3 points")
  const [start, control, end] = points
  return `M ${start.x} ${start.y} Q ${control.x} ${control.y} ${end.x} ${end.y}`
}

export function createCubicPath(points) {
  if (points.length !== 4) throw new Error("Cubic path requires 4 points")
  const [start, ctrl1, ctrl2, end] = points
  return `M ${start.x} ${start.y} C ${ctrl1.x} ${ctrl1.y}, ${ctrl2.x} ${ctrl2.y}, ${end.x} ${end.y}`
}

export function createBezierPath(points) {
  if (points.length < 2) throw new Error("Bezier path requires at least 2 points")
  let d = `M ${points[0].x} ${points[0].y}`
  for (let i = 1; i < points.length; i++) {
    d += ` L ${points[i].x} ${points[i].y}`
  }
  return d
}

export function parsePathData(d) {
  const regex = /[MLCQZ]\s*[^MLCQZ]+/gi
  return d.match(regex) || []
}

export function cloneSVGElement(svgElement, size = 40) {
  const clone = svgElement.cloneNode(true)
  clone.setAttribute("width", size)
  clone.setAttribute("height", size)
  return clone
}

export function serializeSvgElement(element) {
  const obj = {
    tag: element.tagName,
    attrs: {}
  }

  for (const attr of element.attributes) {
    obj.attrs[attr.name] = attr.value
  }

  // Serializar texto si hay
  if (element.childNodes.length === 1 && element.firstChild.nodeType === Node.TEXT_NODE) {
    obj.textContent = element.textContent
  }

  // Caso especial: es una línea/path
  if (element.tagName === "path") {
    obj.strokeData = {
      style: element.dataset.strokeStyle || "solid",
      originalPoints: JSON.parse(element.dataset.points || "[]"),
      type: element.dataset.pathType || "straight" // straight, quadratic, cubic, bezier
    }
  }

  // Serializar hijos (recursivo)
  const children = [...element.children]
  if (children.length > 0) {
    obj.children = children.map(child => this.serializeSvgElement(child))
  }

  return obj
}

export function updateLabel(svgElement, label) {
  let textEl = svgElement.querySelector("text")
  if (!textEl) {
    textEl = createSVGElement("text")
    svgElement.appendChild(textEl)
  }
  textEl.textContent = label
}
