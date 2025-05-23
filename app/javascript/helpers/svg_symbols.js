// app/javascript/controllers/helpers/svg_symbols.js
import { createSVGElement, setAttributes } from "./svg_utils.js"

function parseData(key, fallback = {}) {
  const el = document.getElementById("svg-data")
  if (!el || !el.dataset[key]) return fallback
  try {
    const data = JSON.parse(el.dataset[key])
    return (data && typeof data === "object") ? data : fallback
  } catch {
    return fallback
  }
}

// expected { id: "<symbol>...</symbol>", ... }
const symbolsMap = parseData("symbols", {})

function symbolExists(id) {
  return id in symbolsMap
}

function cloneSymbol(id, options = {}) {
  const { x = 0, y = 0, label = "", transform = null } = options
  
  if (!symbolExists(symbolId)) {
    console.warn(`SVG symbol with id "${symbolId}" not found.`)
    return null
  }
  
  const template = document.querySelector(`symbol#${symbolId}`)
  // Clone the entire content of the <symbol>
  const clone = template.cloneNode(true)
  const group = clone.querySelector("g")
  const element = group || clone

  element.setAttribute("x", x)
  element.setAttribute("y", y)
  element.classList.add("object")
  if (transform) element.setAttribute("transform", transform)

  // If label is provided, find <tspan id="label"> and replace its text
  if (label !== null) {
    const labelSpan = element.querySelector('tspan#label')
    if (labelSpan) {
      labelSpan.textContent = label
    } else {
      console.warn(`Symbol #${symbolId} does not have a <tspan id="label">`)
    }
  }

  // Return the <g> content (directly usable inside an <svg>)
  return element.cloneNode(true)
}

// Add a cloned symbol to a target SVG element
export function addSymbolToSVG(svg, symbolId, options = {}) {
  const cloned = cloneSymbol(symbolId, options)
  if (cloned) svg.appendChild(cloned)
  return cloned
}

// Helper to get list of available symbol IDs
export function listAvailableSymbols() {
  const symbols = document.querySelectorAll("svg defs symbol")
  return Array.from(symbols).map((symbol) => symbol.id)
}

// ✅ SERIALIZE símbol to JSON  (use or group with label)
export function serializeSymbol(el) {
  const isGroup = el.tagName === "g"
  const use = isGroup ? el.querySelector("use") : el
  if (!use || !use.hasAttribute("href")) return null

  const href = use.getAttribute("href") || use.getAttribute("xlink:href")
  const id = href.replace(/^#/, "")

  const x = parseFloat(use.getAttribute("x") || 0)
  const y = parseFloat(use.getAttribute("y") || 0)
  const transform = use.getAttribute("transform") || null

  const obj = {
    tag: isGroup ? "g" : "use",
    symbolId: id,
    attrs: {
      x,
      y,
      ...(transform && { transform }),
      href: `#${id}`,
    },
    classList: Array.from(el.classList),
  }

  // Si tiene texto como label, añadirlo
  if (isGroup) {
    const text = el.querySelector("text")
    if (text) {
      obj.children = [
        {
          tag: "use",
          attrs: {
            x,
            y,
            href: `#${id}`,
            ...(transform && { transform }),
          },
        },
        {
          tag: "text",
          textContent: text.textContent,
          attrs: {
            x,
            y: y + 4,
            "text-anchor": "middle",
          },
        },
      ]
    }
  }

  return obj
}

// ✅ DESERIALIZE symbol from JSON
export function deserializeSymbol(data) {
  if (!data || !data.symbolId) return null

  const tag = data.tag || "use"
  const el = createSVGElement(tag)

  if (data.attrs) setAttributes(el, data.attrs)
  if (data.classList) data.classList.forEach(cls => el.classList.add(cls))

  if (data.children && Array.isArray(data.children)) {
    for (const child of data.children) {
      const childEl = deserializeSymbol(child)
      if (childEl) el.appendChild(childEl)
    }
  }

  return el
}
