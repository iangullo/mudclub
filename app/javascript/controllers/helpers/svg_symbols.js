// app/javascript/controllers/helpers/svg_symbols.js
import { createSVGElement, setAttributes } from "./svg_utils"

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

export function getAvailableSymbols() {
  return Object.keys(symbolsMap)
}

export function cloneSymbol(id, options = {}) {
  const { x = 0, y = 0, label = "", transform = null } = options

  if (!symbolExists(id)) {
    console.warn(`SVG symbol with id "${id}" not found.`)
    return null
  }

  const use = createSVGElement("use")
  use.setAttribute("href", `#${id}`)
  use.setAttribute("x", x)
  use.setAttribute("y", y)
  use.classList.add("object")
  if (transform) use.setAttribute("transform", transform)

  if (label) {
    const group = createSVGElement("g")
    group.classList.add("object")
    group.appendChild(use)

    const text = createSVGElement("text")
    text.textContent = label
    text.setAttribute("x", x)
    text.setAttribute("y", y + 4)
    text.setAttribute("text-anchor", "middle")
    group.appendChild(text)

    return group
  }

  return use
}

export function symbolExists(id) {
  return id in symbolsMap
}

export function getSymbolContent(id) {
  return symbolsMap[id] || null
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
