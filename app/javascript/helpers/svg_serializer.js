// app/javascript/helpers/svg_serializer.js
import { cssColorToHex, generateId, getViewBox, isSVGElement } from "helpers/svg_utils"
const DEBUG = false

// Core element properties for each type
const VALID_PROPERTIES = {
  symbol: ['x', 'y', 'label', 'kind', 'fill', 'stroke', 'textColor', 'transform'],
  path: ['points', 'curve', 'ending', 'style', 'stroke', 'transform']
}

export function serializeDiagram(diagramElement) {
  const symbols = []
  const paths = []
  
  diagramElement.querySelectorAll('g.wrapper').forEach(wrapper => {
    const inner = wrapper.firstElementChild
    if (!inner) return
    
    const type = wrapper.getAttribute("type")
    DEBUG && console.log("wrapper type: ", type)

    if (type === "symbol") {
      const data = serializeSymbol(inner)
      DEBUG && console.log("symbol: ", data)
      if (data) symbols.push(data)
    } else if(type === "path") {
      const data = serializePath(inner)
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

function serializePath(pathGroup) {
  const el = pathGroup?.querySelector('path')
  if (!isSVGElement(pathGroup) || !el) return null

  DEBUG && console.warn(pathGroup.dataset.points)
  const pathPoints = JSON.parse(pathGroup.dataset.points || '[]')
  if (pathPoints.length < 2) return null  // if emtpy, do nothing

  const pathData = {
    id: pathGroup.id || generateId('path'),
    curve: pathGroup.dataset.curve,
    ending: pathGroup.dataset.ending,
    points: pathPoints,
    stroke: cssColorToHex(el.getAttribute('stroke')) || '#000000',
    style: pathGroup.dataset.style
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