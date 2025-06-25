// app/javascript/helpers/svg_symbols.js
import {
  generateId,
  getLabel,
  getViewBox,
  isSVGElement,
  setAttributes,
  setLabel,
  setLogicalTransform,
  wrapContent
} from "helpers/svg_utils"
const DEBUG = true
const SYMBOL_SCALE = 0.07
export const SYMBOL_SIZE = 33.87

// put a new symbol on the canvas
export function createSymbol(svg, symbolId, kind, label, x = null, y = null) {
  DEBUG && console.log("creating new object {symbolId:", symbolId,", kind: ", kind, ", label: ", label, ", x: ",x, ", y:", y, "}")
  const { width, height } = getViewBox(svg)
  DEBUG && console.log("viewbox limits: [", width, " x ", height, "]")
  const x0 = x || width * 0.2
  const y0 = y || height * 0.3

  return addSymbolToSVG(svg, symbolId, {label: label, kind: kind, x: x0, y: y0})
}

export function getObjectNumber(element) {
  const label = element.querySelector('tspan#label')
  if (label) {
    const val = parseInt(label.textContent, 10)
    return isNaN(val) ? null : val
  }
  return null
}

export function updateSymbol(el, data = {}) {
  if (!isSVGElement(el)) return null

  const before = serializeSymbol(el)
  const changes = {}

  // Handle label update
  if ("label" in data && getLabel(el) !== data.label) {
    setLabel(el, data.label)
    changes.label = data.label
  }

  // Handle styles
  const styleAttrs = ["fill", "stroke", "textColor"]
  styleAttrs.forEach(attr => {
    if (attr in data) {
      const target = attr === "textColor" ? el.querySelector("text") : el
      if (target?.getAttribute(attr) !== data[attr]) {
        target.setAttribute(attr, data[attr])
        changes[attr] = data[attr]
      }
    }
  })

  return Object.keys(changes).length ? {before, after: serializeSymbol(el)} : null
}

export function validateSymbol(data) {
  return data && 
    data.type === 'symbol' &&
    typeof data.symbol_id === 'string' &&
    typeof data.x === 'number' && 
    typeof data.y === 'number' &&
    (data.label === undefined || typeof data.label === 'string')
}

// internal support functions
function addSymbolToSVG(svg, symbolId, options = {}) {
  const { x = 0, y = 0 } = options
 
  const clone = cloneSymbol(symbolId, options)
  
  if (clone) {
    DEBUG && console.log("appending symbol: ", symbolId)
    // Calculate proper scale for 7% of viewbox height
    const viewBoxHeight = svg.viewBox.baseVal.height
    const desiredHeight = viewBoxHeight * SYMBOL_SCALE
    const objScale = desiredHeight / SYMBOL_SIZE // Original symbol size
    // return wrapped content to manage scaling
    const wrapper = wrapContent(clone, x, y, objScale, "symbol")

    svg.appendChild(wrapper)
    return wrapper
  }
  return null
}

function cloneSymbol(symbolId, options = {}) {
  DEBUG && console.log("cloneSymbol:", { symbolId, options })
  
  const { id = generateId(), label = "", kind = null } = options
  const templateSVG = document.querySelector(`#diagram-editor-buttons svg[data-symbol-id="${symbolId}"]`)
  
  if (!templateSVG) {
    DEBUG && console.warn(`Symbol template not found for ID: ${symbolId}`)
    return null
  }

  const templateGroup = templateSVG.querySelector("g")
  if (!templateGroup) {
    DEBUG && console.warn(`No <g> element found in symbol template: ${symbolId}`)
    return null
  }

  const clone = templateGroup.cloneNode(true)
  setAttributes(clone, {
    id,
    "data-symbol-id": symbolId,
    "data-kind": kind,
    "data-x": options.x || 0,
    "data-y": options.y || 0
  })

  if (label) setLabel(clone, label)
  if (options.transform) setLogicalTransform(clone, options.transform)

  return clone
}