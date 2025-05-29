// app/javascript/controllers/helpers/svg_symbols.js
import {
  createSvgElement,
  generateId,
  isSVGElement,
  setAttributes,
  setLabel,
  setLogicalTransform,
  setVisualTransform
} from "helpers/svg_utils"
const DEBUG = true
export const SYMBOL_SIZE = 33.87

function cloneSymbol(symbolId, options = {}) {
  DEBUG && console.log("cloneSymbo(", symbolId,", options={", options, "}")
  const templateSVG = document.querySelector(`#diagram-editor-buttons svg[data-symbol-id="${symbolId}"]`)
  if (!templateSVG) return null
  DEBUG && console.log("templateSVG: ", templateSVG)

  // If you want the first <g> only (assuming symbols have one root <g>)
  const templateGroup = templateSVG.querySelector("g")
  if (!templateGroup) return null

  // Clone the <g> itself
  const clone = templateGroup.cloneNode(true)
  clone.classList.add("draggable")
  clone.setAttribute("draggable", "true")
  const { id = generateId(), x = 0, y = 0, label = "", transform = null, kind = null, scale = 1 } = options
  
  // ✅ Add dataset attributes for reliable serialization
  const objectId = id
  setAttributes(clone, {"id": objectId, "symbolId": symbolId, kind: kind, x: x, y: y})
  setLabel(clone, label)
  setLogicalTransform(clone, transform)
  DEBUG && console.log("cloned Symbol: ", clone)

  // Prepare the outer wrapper <g> to apply visual scale only
  const wrapper = createSvgElement("g")
  wrapper.classList.add("draggable-wrapper") // if you want to style/debug
  wrapper.setAttribute("id", `${id}-wrapper`)
  setVisualTransform(wrapper, {x, y, scale})
  wrapper.appendChild(clone)  // copy cloned symbol inside
  DEBUG && console.log("Symbol wrapper: ", wrapper)
  return wrapper
}

// Add a cloned symbol to a target SVG element
export function addSymbolToSVG(svg, symbolId, options = {}) {
  const cloned = cloneSymbol(symbolId, options)
  if (cloned) {
    DEBUG && console.log("appending symbol: ", symbolId)
    svg.appendChild(cloned)
    return cloned
  }
  return null
}

// ✅ DESERIALIZE symbol from JSON
export function deserializeSymbol(data) {
  if (!data || !data.symbol_id) return null

  const el = cloneSymbol(data.symbol_id, {
    label: data.label || "",
    transform: data.transform || "translate(0,0)",
    id: data.id,
    kind: data.kind,
    size: data.size,
    x: data.x || 0,
    y: data.y || 0
  })

  if (!el) return null

  // Optional styles
  setAttributes(el, {
    fill: data.fill,
    stroke: data.stroke,
  })

  // Text color
  if (data.textColor) {
    const text = el.querySelector("text")
    if (text) setAttributes(text, { fill: data.textColor })
  }

  return el
}

// ✅ SERIALIZE símbol to JSON  (use or group with label)
export function serializeSymbol(el) {
  if (!isSVGElement(el)) return null

  const symbolId = el.dataset.symbolId
  if (!symbolId) return null

  const obj = {
    id: el.id || generateId(),
    symbol_id: symbolId,
    type: "object",
    kind: el.getAttribute("kind"),
    x: el.dataset.x || 0,
    y: el.dataset.y || 0,
    transform: el.getAttribute("transform") || "translate(0,0)",
  }

  if (el.hasAttribute("size")) obj.fill = el.getAttribute("size")
  if (el.hasAttribute("fill")) obj.fill = el.getAttribute("fill")
  if (el.hasAttribute("stroke")) obj.stroke = el.getAttribute("stroke")

  const textEl = el.querySelector("text")
  if (textEl) {
    obj.label = textEl.textContent
    if (textEl.hasAttribute("fill")) obj.textColor = textEl.getAttribute("fill")
  }

  return obj
}

export function updateSymbol(el, data = {}) {
  if (!el || !(el instanceof SVGElement)) return null

  const before = serializeSymbol(el) // snapshot before changes
  let changed = false

  // Label
  if ("label" in data) {
    const labelTspan = el.querySelector('tspan[id^="label"]')
    if (labelTspan && labelTspan.textContent !== data.label) {
      labelTspan.textContent = data.label
      changed = true
    }
  }

  // Fill
  if ("fill" in data && el.getAttribute("fill") !== data.fill) {
    el.setAttribute("fill", data.fill)
    changed = true
  }

  // Stroke
  if ("stroke" in data && el.getAttribute("stroke") !== data.stroke) {
    el.setAttribute("stroke", data.stroke)
    changed = true
  }

  // Text color (inside <text>)
  if ("textColor" in data) {
    const text = el.querySelector("text")
    if (text && text.getAttribute("fill") !== data.textColor) {
      text.setAttribute("fill", data.textColor)
      changed = true
    }
  }

  // Handle transform directly
  if ("transform" in data && el.getAttribute("transform") !== data.transform) {
    el.setAttribute("transform", data.transform)
    changed = true
  }

  // Optional handling of x/y -> transform
  if (("x" in data && "y" in data) && !("transform" in data)) {
    const generatedTransform = `translate(${data.x},${data.y})`
    if (el.getAttribute("transform") !== generatedTransform) {
      el.setAttribute("transform", generatedTransform)
      changed = true
    }
  }

  // Return undo info if changed
  return changed ? { before, after: serializeSymbol(el) } : null
}

export function getObjectNumber(element) {
  const label = element.querySelector('tspan#label')
  if (label) {
    const val = parseInt(label.textContent, 10)
    return isNaN(val) ? null : val
  }
  return null
}
