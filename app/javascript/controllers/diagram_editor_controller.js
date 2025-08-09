// app/stimulus/controllers/diagram_editor_controller.js
// Developed with significant help from DeepSeek
// Attempt at a responsive and dynamic diagram editor.
import { Controller } from "@hotwired/stimulus"
import { loadDiagramContent, findLowestAvailableNumber, zoomToFit } from "helpers/svg_loader"
import { createPath, updatePath, MIN_POINTS_FOR_CURVE } from "helpers/svg_paths"
import { serializeDiagram } from "helpers/svg_serializer"
import { SYMBOL_SIZE, createSymbol, getObjectNumber } from "helpers/svg_symbols"
import { findElementNearPoint, getPointFromEvent, getInnerElement, updatePosition } from "helpers/svg_utils"

const SYMBOL_PREVIEW_OPACITY = 0.7
const SYMBOL_PLACEMENT_DURATION = 300
const DEBUG = false

export default class extends Controller {
  static targets = ["diagram", "court", "svgdata", "deleteButton"]

  // --- [1] editor startup functions ---
  connect() {
    this.setupEventListeners()
    this.resetDrawingState()
    requestAnimationFrame(() => {
      this.scale = zoomToFit(this.diagramTarget, this.courtTarget, true)
    })
  }
  
  initialize() {
    this.mode = 'idle'   // 'idle', 'drawing', 'editing'
    const { attackers, defenders } = loadDiagramContent(this.diagramTarget, this.svgdataTarget.value, true)
    this.attackerNumbers = attackers
    this.defenderNumbers = defenders
    this.selectedElement = null
    this.draggedElement = null
    this.courtBox = this.courtTarget.getBBox()  // <- returns {x, y, width, height}
  }

  setupEventListeners() {
    this.handleResize = () => {
      this.scale = zoomToFit(this.diagramTarget, this.courtTarget, true)
    }

    this.onClick = this.onClick.bind(this)
    this.onDblClick = this.onDblClick.bind(this)
    this.onPointerDown = this.onPointerDown.bind(this)
    this.onPointerMove = this.onPointerMove.bind(this)
    this.onPointerUp = this.onPointerUp.bind(this)
    this.onKeyDown = this.onKeyDown.bind(this)

    this.diagramTarget.addEventListener('click', this.onClick)
    this.diagramTarget.addEventListener('dblclick', this.onDblClick)
    this.diagramTarget.addEventListener('pointerdown', this.onPointerDown)
    window.addEventListener('resize', this.handleResize)
    window.addEventListener('pointermove', this.onPointerMove)
    window.addEventListener('pointerup', this.onPointerUp)
    window.addEventListener('keydown', this.onKeyDown)
  }

  disconnect() {
    this.diagramTarget.removeEventListener('click', this.onClick)
    this.diagramTarget.removeEventListener('dblclick', this.onDblClick)
    this.diagramTarget.removeEventListener('pointerdown', this.onPointerDown)
    window.removeEventListener('resize', this.handleResize)
    window.removeEventListener('pointermove', this.onPointerMove)
    window.removeEventListener('pointerup', this.onPointerUp)
    window.removeEventListener('keydown', this.onKeyDown)
  }

  // --- [2] SVG object creation ---
  addAttacker(event) { this.addObject(event, "attacker", this.attackerNumbers) }
  addBall(event) { this.addObject(event, "ball") }
  addCoach(event) { this.addObject(event, "coach") }
  addCone(event) { this.addObject(event, "cone", null, 0.07) }
  addDefender(event) { this.addObject(event, "defender", this.defenderNumbers) }

  addObject(event, kind, set = null) {
    const button = event.currentTarget
    const svg = button.querySelector("svg[data-symbol-id]")
    const symbolId = svg?.dataset.symbolId
    if (!symbolId) {
      DEBUG && console.warn("button has not symbolId: ", button)
      return
    }

    // Enter symbol placement mode
    this.enterSymbolPlacementMode(symbolId, kind, set)
  }

  enterSymbolPlacementMode(symbolId, kind, set) {
    // Clear any existing placement
    this.cancelPlacement()

    const number = set ? findLowestAvailableNumber(set) : null
    if (number) set.add(number)
    // Create preview symbol
    this.placementSymbol = createSymbol(
      {symbol_id: symbolId, kind: kind, label: number}, 
      this.courtBox.height
    )
    // Add to player counts
    if (kind === 'attacker') {
      this.attackerNumbers.add(number)
    } else if (kind === 'defender') {
      this.defenderNumbers.add(number)
    }
    // Style preview symbol
    this.placementSymbol.style.opacity = SYMBOL_PREVIEW_OPACITY
    this.placementSymbol.style.cursor = 'grabbing'
    this.placementSymbol.classList.add('placement-preview')
    
    // Add to diagram
    this.diagramTarget.appendChild(this.placementSymbol)
    
    // Set placement mode
    this.mode = 'placing'
    this.placementKind = kind
    this.placementSet = set
    
    // Add temporary move listener
    this.diagramTarget.addEventListener('pointermove', this.handlePlacementMove)
    this.diagramTarget.addEventListener('click', this.handlePlacementClick)
    this.diagramTarget.addEventListener('pointerleave', this.cancelPlacement)
  }
  
  handlePlacementMove = (event) => {
    if (!this.placementSymbol) return
    
    const point = getPointFromEvent(event, this.diagramTarget)
    const inner = getInnerElement(this.placementSymbol)
    
    if (inner) {
      // Update position with smooth transition
      inner.style.transition = 'transform 0.1s ease-out'
      updatePosition(inner, point.x, point.y)
    }
  }
  
  handlePlacementClick = (event) => {
    if (!this.placementSymbol) return
    
    const point = getPointFromEvent(event, this.diagramTarget)
    const inner = getInnerElement(this.placementSymbol)
    
    if (inner) {
      // Apply final styles
      this.placementSymbol.style.opacity = '1'
      this.placementSymbol.style.transition = `opacity ${SYMBOL_PLACEMENT_DURATION}ms ease-out`
      this.placementSymbol.classList.remove('placement-preview')
      
      // Add pulse animation
      this.placementSymbol.classList.add('pulse-animation')
      setTimeout(() => {
        if (this.placementSymbol) {
          this.placementSymbol.classList.remove('pulse-animation')
        }
      }, 1000)
      
      // Clear placement state
      this.cleanupPlacementMode()
    }
  }
  
  cancelPlacement = () => {
    if (this.placementSymbol) {
      this.placementSymbol.classList.add('fade-out')
      setTimeout(() => {
        if (this.placementSymbol && this.placementSymbol.parentNode) {
          this.deleteSymbolCounter(this.placementSymbol)
          this.placementSymbol.parentNode.removeChild(this.placementSymbol)
        }
        this.cleanupPlacementMode()
      }, SYMBOL_PLACEMENT_DURATION)
    }
  }
  
  cleanupPlacementMode() {
    this.diagramTarget.removeEventListener('pointermove', this.handlePlacementMove)
    this.diagramTarget.removeEventListener('click', this.handlePlacementClick)
    this.diagramTarget.removeEventListener('pointerleave', this.cancelPlacement)
    
    this.placementSymbol = null
    this.placementKind = null
    this.placementSet = null
    this.mode = 'idle'
  }

  // --- [4] Line drawing functions ---
  startDrawing(event) {
    const button = event.currentTarget
    DEBUG && console.log("startDrawing ", button)

    if (this.mode === 'drawing') {
      const end_drawing = (this.activeDrawingButton === button)
      this.stopDrawing()
      if (end_drawing) return

    }

    this.resetDrawingState('drawing')
    this.activeDrawingButton = button
    this.highlightButton(button)

    this.drawingParams = {
      curve: button.dataset.curve === 'true',
      style: button.dataset.style || 'solid',
      ending: button.dataset.ending || 'none',
      isPreview: true,
      scale: this.scale
    }
    DEBUG && console.log("drawingParams ", this.drawingParams)
    this.tempPath = createPath(this.drawingPoints, this.drawingParams)
    this.diagramTarget.appendChild(this.tempPath)
  
    // Store reference to the actual path element
    this.tempPathGroup = this.tempPath.querySelector('g')
  }

  addDrawingPoint(event) {
    if (this.mode !== 'drawing') return
    this.drawingParams.scale = this.scale
    const point = getPointFromEvent(event, this.diagramTarget)
    
    // Skip duplicate points (within 1px tolerance)
    if (this.drawingPoints.length > 2) {
      const lastPoint = this.drawingPoints[this.drawingPoints.length - 1]
      const dx = point.x - lastPoint.x
      const dy = point.y - lastPoint.y
      const distanceSquared = dx * dx + dy * dy
      
      if (distanceSquared < 1) {  // 1px² tolerance
        DEBUG && console.log("Skipping duplicate point", point)
        return
      }
    }
    
    DEBUG && console.log("addDrawingPoint ", point)
    this.drawingPoints.push(point)
    
    // Update the path with the new fixed point
    if (!this.drawingParams.curve && this.drawingPoints.length === 2) {
      this.finalizeDrawing()
    } else if (this.drawingPoints.length >= 2) {
      updatePath(this.tempPathGroup, this.drawingPoints, this.drawingParams)
    }
  }

  trackDrawingPointer(event) {
    if (this.mode !== 'drawing' || this.drawingPoints.length === 0) return

    // Get current cursor position
    this.currentPoint = getPointFromEvent(event, this.diagramTarget)
    //DEBUG && console.log("trackDrawingPointer ", this.currentPoint)    

    // Combine fixed points with current cursor position
    const tempPoints = [...this.drawingPoints, this.currentPoint]

    // Update existing path with fixed points + current cursor position
    updatePath(this.tempPathGroup, tempPoints, this.drawingParams)
  }

  finalizeDrawing() {
    DEBUG && console.log("finalizeDrawing()")
    if (this.mode !== 'drawing') return
    if (this.drawingPoints.length < 2 || (this.drawingParams.curve && this.drawingPoints.length < MIN_POINTS_FOR_CURVE)) {
      return this.stopDrawing()
    }

    this.drawingParams.color = this.activeDrawingButton.dataset.color || '#000000'  // re-set color
    this.drawingParams.isPreview = false
    updatePath(this.tempPathGroup, this.drawingPoints, this.drawingParams)
    this.resetDrawingState()
  }

  stopDrawing() {
    DEBUG && console.log("stopDrawing()")
    this.currentPoint = null
    this.resetDrawingState()
    if (this.tempPath) {
      this.diagramTarget.removeChild(this.tempPath)
      this.tempPath = null
    }
    this.activeDrawingButton = null
  }

  resetDrawingState(mode = 'idle') {
    DEBUG && console.log("resetDrawingState()")
    this.unhighlightButton(this.activeDrawingButton)
    this.drawingPoints = []
    this.drawingParams = {}
    this.currentPoint = null
    this.mode = mode
  }

  highlightButton(button) {
    DEBUG && console.log("highlighButton()")
    if (!button) return
    const activeClass = button.dataset.activeClass || "bg-blue-400 text-white ring"
    button.classList.add(...activeClass.split(" "))
  }

  unhighlightButton(button) {
    DEBUG && console.log("unhighlighButton()")
    if (!button) return
    const activeClass = button.dataset.activeClass || ""
    button.classList.remove(...activeClass.split(" "))
  }

  // --- [5] Manage object selection & removal ---
  clearSelection() {
    if (this.selectedElement) {
      DEBUG && console.log("clearSelection: ", this.selectedElement)
      this.lowlightElement(this.selectedElement)
      const indicator = this.selectedElement.querySelector('.selection-indicator')
      if (indicator) indicator.remove()

      this.selectedElement = null
    }
    this.deleteButtonTarget.disabled = true
  }

  deleteSelected() {
    const wrapper = this.selectedElement
    if (!wrapper) return

    this.deleteSymbolCounter(wrapper)
    wrapper.classList.add('opacity-0', 'transition-opacity', 'duration-300')
    setTimeout(() => {
      wrapper.remove()
      this.selectedElement = null
      this.deleteButtonTarget.disabled = true
    }, 300)
  }

  deleteSymbolCounter(wrapper) {
    DEBUG && console.warn("deleteSymbolCounter(",wrapper,")")
    const inner = getInnerElement(wrapper)
    if (!inner) {
      DEBUG && console.warn("No inner object to delete inside wrapper")
      return
    }

    const kind = inner.getAttribute('kind') || inner.dataset.kind
    DEBUG && console.log("inner object:", inner)

    if ((kind === "attacker") || (kind === "defender")) {
      const number = getObjectNumber(inner)
      if (number) {
        DEBUG && console.log(`Removing ${kind} number ${number}`)
        kind === 'attacker'
          ? this.attackerNumbers.delete(number)
          : this.defenderNumbers.delete(number)
      }
    }
  }

  getSelectionTolerance() {
    return SELECTION_TOLERANCE / this.scale
  }

  handleSelection(evt) {
    this.clearSelection() // Deselect previous element, if any
    const point = getPointFromEvent(evt, this.diagramTarget)
  
    // First try exact element under pointer
    let wrapper = evt.target.closest('g.wrapper')

    if (!wrapper) {  // Select the new group and highlight it
      wrapper = findElementNearPoint(this.diagramTarget, point)
    }

    if (wrapper) {
      this.selectedElement = wrapper
      this.highlightElement(wrapper)
      this.deleteButtonTarget.disabled = false

      if (DEBUG) {
        const inner = getInnerElement(wrapper)
        console.log("Selected:", {
          wrapper: wrapper.id,
          kind: inner?.dataset.kind,
          number: inner ? getObjectNumber(inner) : null
        })
      }
    }
  }

  highlightElement(el) {
    if (el.tagName === 'path') {
      // Store original styles
      if (!el.dataset.originalStroke) el.dataset.originalStroke = el.style.stroke || ''
      if (!el.dataset.originalStrokeWidth) el.dataset.originalStrokeWidth = el.style.strokeWidth || ''
      if (!el.dataset.originalFill) el.dataset.originalFill = el.style.fill || ''
      el.style.stroke = 'red' // Apply selection styles
      el.style.strokeWidth = '4px'
      el.style.fill = 'rgba(255, 0, 0, 0.2)'
    } else if (el.tagName === 'g') {  // Store original filter/fill
      if (!el.dataset.originalFilter) el.dataset.originalFilter = el.style.filter || ''
      if (!el.dataset.originalFill) el.dataset.originalFill = el.style.fill || ''
      el.style.filter = 'drop-shadow(0 0 10px rgba(255, 0, 0, 0.5))'
      el.style.fill = 'rgba(255, 0, 0, 0.2)'
    }
  }

  lowlightElement(el) {
    if (el.tagName === 'path') {
      el.style.stroke = el.dataset.originalStroke || ''
      el.style.strokeWidth = el.dataset.originalStrokeWidth || ''
      el.style.fill = el.dataset.originalFill || ''
      delete el.dataset.originalStroke
      delete el.dataset.originalStrokeWidth
      delete el.dataset.originalFill
    } else if (el.tagName === 'g') {
      el.style.filter = el.dataset.originalFilter || ''
      el.style.fill = el.dataset.originalFill || ''
      delete el.dataset.originalFilter
      delete el.dataset.originalFill
    }
  }

  // --- [6] Auxiliary diagram editing ---
  clearActiveLineButtons() {
    const buttons = this.element.querySelectorAll("[data-action*='startDrawing']")
    buttons.forEach(btn => {
      const activeClass = btn.dataset.activeClass || ""
      btn.classList.remove(...activeClass.split(" "))
    })
  }

  onClick(evt) {
    if (this.isDrawing()) {
      this.addDrawingPoint(evt)
    } else {
      this.handleSelection(evt)
    }
  }

  onDblClick(evt) {
    const target = evt.target

    if (this.isDrawing()) {
      this.finalizeDrawing()
      return
    }
  }

  onKeyDown(evt) {
    switch (evt.key) {
      case 'Escape':
        if (this.isDrawing()) {
          this.stopDrawing() // discard changes
        } else {  //idle mode -- deselect selected object
          this.clearSelection()
        }
        break
      case 'Delete':
        this.deleteSelected()
      default:
        return

    }

  }

  onPointerDown(evt) {
    if (this.isIdle) {
      this.dragStart(evt)
    }
  }

  onPointerMove(evt) {
    if (this.isDrawing()) {
      this.trackDrawingPointer(evt)
    } else if (this.isIdle && this.draggedWrapper) {
      this.drag(evt)  // Move a regular object
    }
  }

  onPointerUp(evt) {
    if (this.isIdle && this.draggedWrapper) {
      this.dragEnd(evt)   // Complete the object dragging
    }
  }

  // Helper methods to check current mode
  isDrawing() {
    return this.mode === 'drawing'
  }

  isIdle() {
    return this.mode === 'idle'
  }

  // Dragging
  dragStart(evt) {
    const wrapper = evt.target.closest('g.wrapper')
    if (!wrapper) return
    
    this.draggedWrapper = wrapper
    this.draggedType = wrapper.getAttribute('type') || 'symbol'
    if (this.draggedType != 'symbol') return

    const inner = getInnerElement(wrapper)
    if (!inner) return
    this.draggedInner = inner

    DEBUG && console.log("dragStart: ", wrapper.getAttribute("id"), "inner: ", inner.getAttribute("id"))
    DEBUG && console.log("coordinates: [", inner.getAttribute("y"), ", ", inner.getAttribute("y"), "]")
    document.body.style.cursor = 'grabbing'
    evt.preventDefault()
  }

  // Track current position using SVG coordinates
  drag(evt) {
    if (!this.draggedInner) return

    const pt = getPointFromEvent(evt, this.diagramTarget)
    DEBUG && console.log("drag([", pt.x, ", ", pt.y, "])")

    const { x: minX, y: minY, width, height } = this.courtBox
    const maxX = minX + width - 3*SYMBOL_SIZE
    const maxY = minY + height - 3*SYMBOL_SIZE
    // Bail out if outside allowed area (based on logical coords)
    if (pt.x < minX || pt.x > maxX || pt.y < minY || pt.y > maxY) {
      DEBUG && console.log("Blocked drag outside court:", pt.x, pt.y)
      return
    }

    // Update logical position on inner <g>
    updatePosition(this.draggedInner, pt.x, pt.y)
    evt.preventDefault()
  }

  dragEnd() {
    document.body.style.cursor = ''
    if (this.draggedWrapper && this.draggedInner) {
      const x = this.draggedInner.dataset.x
      const y = this.draggedInner.dataset.y
      DEBUG && console.log("dragEnd:", this.draggedWrapper.id, "coords:", x, y)
    }
    this.draggedWrapper = null
    this.draggedInner = null
  }

  // --- [END] SERIALIZE CONTENT ---/
  serialize() {
    const data = serializeDiagram(this.diagramTarget)
    this.svgdataTarget.value = JSON.stringify(data)
    DEBUG && console.log("Serialized data:", data)
  }
}