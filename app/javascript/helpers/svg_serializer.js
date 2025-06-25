// app/javascript/helpers/svg_serializer.js
import { cssColorToHex, getViewBox, isSVGElement } from "helpers/svg_utils"
const DEBUG = true

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

  const pathData = {
    id: el.id || generateId,
    curve: el.getAttribute('curve'),
    ending: el.getAttribute('ending'),
    points: JSON.parse(el.dataset.points || '[]'),
    stroke: cssColorToHex(el.getAttribute('stroke')) || '#000000',
    style: el.getAttribute('style')
  }
  DEBUG && console.log("serialized: ", pathData)

  return pathData
}

function serializeSymbol(el) {
  if (!isSVGElement(el)) return null

  const textElement = el.querySelector('text')
  const symbolData = {
    id: el.id || generateId,
    kind: el.dataset.kind,
    symbol_id: el.dataset.symbolId,
    transform: el.getAttribute('transform') || null,
    x: parseFloat(el.dataset.x) || 0,
    y: parseFloat(el.dataset.y) || 0,
    label: el.dataset.label || 
           textElement?.textContent?.trim() || 
           el.querySelector('tspan#label')?.textContent?.trim()
  }
  DEBUG && console.log("serialized: ", symbolData)
  return symbolData
}
