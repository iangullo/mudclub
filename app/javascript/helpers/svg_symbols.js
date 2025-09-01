// app/javascript/helpers/svg_symbols.js
import {
  generateId,
  getInnerGroup,
  getLabel,
  isSVGElement,
  setAttributes,
  setLabel,
  updatePosition,
  wrapContent
} from 'helpers/svg_utils'
export const SYMBOL_SIZE = 33.87
const SYMBOL_SCALE = 0.07
const EPSILON = 0.01
const DEBUG = false

export function applySymbolColor(symbolElement, color) {
  const kind = symbolElement.getAttribute('kind')
  const labelSpan = symbolElement.querySelector('tspan[id^="label"]')

  if (labelSpan) { labelSpan.style.fill = color }

  // some management for different kinds
  switch (kind) {
    case 'attacker':
      symbolElement.setAttribute('stroke', color)
      symbolElement.style.stroke = color
      break
    default:  // solid
      symbolElement.style.stroke = color
      symbolElement.setAttribute('stroke', color)
      symbolElement.style.fill = color
      symbolElement.setAttribute('fill', color)
      break
  }
}

// put a new symbol on the canvas
export function createSymbol(symbolData, svgHeight) {
  DEBUG && console.log('createSymbol: ', symbolData, svgHeight)
  const opts = validateSymbolData(symbolData)
  const symbolDef = document.getElementById(opts.symbolId)

  if (!symbolDef) {
    DEBUG && console.warn(`Symbol definition not found: ${opts.symbolId}`)
    return null
  }

  DEBUG && console.log('found symbol definition: ', symbolDef)

  const symbolElement = symbolDef.querySelector('g').cloneNode(true)
  setAttributes(symbolElement, {
    id: opts.id,
    draggable: true,
    fill: opts.fill,
    kind: opts.kind,
    stroke: opts.stroke,
    symbolId: opts.symbolId,
  })

  const tcolor = (opts.kind === 'defender') ? opts.fill : opts.stroke
  if (opts.label) setLabel(symbolElement, opts.label, tcolor)
  updateSymbolScale(symbolElement, svgHeight)
  updatePosition(symbolElement, opts.x, opts.y)

  return wrapContent(symbolElement, 'symbol', false)
}

export function getObjectNumber(element) {
  const label = element.querySelector('tspan#label')
  if (label) {
    const val = parseInt(label.textContent, 10)
    return isNaN(val) ? null : val
  }
  return null
}

export function isPlayer(wrapper) {
  const inner = getInnerGroup(wrapper)
  if (!inner) {
    DEBUG && console.warn('No inner object to delete inside wrapper')
    return null
  }

  const kind = inner.getAttribute('kind') || inner.dataset.kind
  DEBUG && console.log('inner object:', inner)

  if ((kind === 'attacker') || (kind === 'defender')) {
    return { kind: kind, number: getObjectNumber(inner) }
  }

  return null
}

export function updateSymbol(el, data = {}) {
  if (!isSVGElement(el)) return null

  const before = serializeSymbol(el)
  const changes = {}

  // Handle label update
  if ('label' in data && getLabel(el) !== data.label) {
    setLabel(el, data.label)
    changes.label = data.label
  }

  // Handle styles
  const styleAttrs = ['fill', 'stroke']
  styleAttrs.forEach(attr => {
    if (attr in data) {
      if (el?.getAttribute(attr) !== data[attr]) {
        el.setAttribute(attr, data[attr])
        changes[attr] = data[attr]
      }
    }
  })

  return Object.keys(changes).length ? { before, after: serializeSymbol(el) } : null
}

export function validateSymbol(data) {
  return data &&
    data.type === 'symbol' &&
    typeof data.kind === 'string' &&
    typeof data.symbol_id === 'string' &&
    typeof data.x === 'number' &&
    typeof data.y === 'number' &&
    (data.label === undefined || typeof data.label === 'string')
}

// only used on symbol creation really
function updateSymbolScale(symbol, svgHeight) {
  DEBUG && console.log('applyScale(symbol:', symbol.id, ', svgHeight:', svgHeight, ')')

  // Get existing transform attribute
  let transform = symbol.getAttribute('transform') || ''

  // Idempotency check - we avoid updating if we had similar scale already
  const scaleMatch = transform.match(/scale\(([^)]+)\)/)
  const currentScale = scaleMatch ? parseFloat(scaleMatch[1]) : null
  const objScale = svgHeight * (SYMBOL_SCALE / SYMBOL_SIZE) // normalized scale for symbol
  if (currentScale !== null && Math.abs(currentScale - objScale) < EPSILON) {
    DEBUG && console.log('Scale already applied, skipping.')
    return
  }

  let updated = false
  // Replace existing scale if found
  transform = transform.replace(/scale\([^)]+\)/, () => {
    updated = true
    return `scale(${objScale})`
  })

  // Append scale if none found
  if (!updated) {
    transform += ` scale(${objScale})`
  }

  // Clean up extra spaces
  transform = transform.trim().replace(/\s+/g, ' ')

  symbol.setAttribute('transform', transform)
  DEBUG && console.log('applied transform:', transform)
}

// sanitize received options
function validateSymbolData(options) {
  return {
    id: options.id || generateId('sym'),
    kind: ['attacker', 'ball', 'coach', 'cone', 'defender'].includes(options.kind) ? options.kind : 'atacker',
    fill: options.fill,
    label: options.label || null,
    stroke: options.stroke,
    symbolId: options.symbol_id,
    transform: options.transform || null,
    x: options.x || 20,
    y: options.y || 20
  }
}
