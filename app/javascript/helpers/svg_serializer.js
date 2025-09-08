// app/javascript/helpers/svg_serializer.js
import { generateId, getViewBox, isSVGElement } from "helpers/svg_utils"
const DEBUG = false

// Core element properties for each type
const VALID_PROPERTIES = {
  symbol: ['x', 'y', 'label', 'kind', 'fill', 'stroke', 'transform'],
  path: ['points', 'curve', 'ending', 'style', 'stroke', 'transform']
}

export function serializeDiagram(diagramElement) {
  const symbols = []
  const paths = []

  diagramElement.querySelectorAll('g.wrapper').forEach(wrapper => {
    DEBUG && console.log("wrapper: ", wrapper)

    const type = wrapper.getAttribute("type")
    DEBUG && console.log("object type: ", type)

    if (type === "symbol") {
      const data = serializeSymbol(wrapper)
      DEBUG && console.log("symbol: ", data)
      if (data) symbols.push(data)
    } else if (type === "path") {
      const data = serializePath(wrapper)
      DEBUG && console.log("path: ", data)
      if (data) paths.push(data)
    }
  })
  DEBUG && console.log("symbols: ", symbols)
  DEBUG && console.log("paths: ", paths)
  return {
    viewBox: getViewBox(diagramElement),
    symbols: symbols,
    paths: paths
  }
}

function serializePath(el) {
  DEBUG && console.log("serializePath", el)
  if (!isSVGElement(el)) return null

  DEBUG && console.warn(el.dataset.points)
  let pathPoints = []
  try {
    pathPoints = JSON.parse(el.dataset.points || '[]')
  } catch (e) {
    console.error('Error parsing path points:', e)
  }
  if (pathPoints.length < 2) return null  // if empty, do nothing

  const pathData = {
    id: el.id || generateId('path'),
    curve: el.dataset.curve,
    ending: el.dataset.ending,
    points: pathPoints,
    color: el.dataset.color || '#000000',
    style: el.dataset.style
  }
  DEBUG && console.log("serialized: ", pathData)

  return pathData
}

function serializeSymbol(el) {
  if (!isSVGElement(el)) return null

  const textElement = el.querySelector('text')
  const symbolData = {
    id: el.getAttribute('id') || generateId('sym'),
    fill: el.getAttribute('fill'),
    kind: el.getAttribute('kind'),
    stroke: el.getAttribute('stroke'),
    symbol_id: el.getAttribute('symbolId'),
    x: parseFloat(el.dataset.x) || 0,
    y: parseFloat(el.dataset.y) || 0,
    label: el.getAttribute('label') ||
      textElement?.textContent?.trim() ||
      el.querySelector('tspan#label')?.textContent?.trim()
  }
  DEBUG && console.log("serialized: ", symbolData)
  return symbolData
}