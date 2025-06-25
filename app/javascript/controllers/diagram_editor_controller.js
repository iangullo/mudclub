// app/stimulus/controllers/diagram_editor_controller.js
// Attempt at a responsive and dynamic diagram editor.
import { Controller } from "@hotwired/stimulus"
import { parseDiagramContent, findLowestAvailableNumber, zoomToFit } from "helpers/svg_loader"
import { createPath, updatePath } from "helpers/svg_paths"
import { serializeDiagram } from "helpers/svg_serializer"
import { SYMBOL_SIZE, createSymbol, getObjectNumber } from "helpers/svg_symbols"
import { getPointFromEvent, getInnerElement, setVisualTransform } from "helpers/svg_utils"

const DEBUG = true

export default class extends Controller {
  static targets = ["diagram", "court", "svgdata", "deleteButton"]

  // --- [1] editor startup functions ---
  connect() {
    this.initialize()

    // Initialize drawing state
    this.drawing = false
    this.drawPoints = []
    this.selectedElement = null
    this.draggedElement = null
    this.handleIndex = null
    this.offset = { x: 0, y: 0 }

    // Bind methods
    this.onClick = this.onClick.bind(this)
    this.onDblClick = this.onDblClick.bind(this)
    this.onKeyDown = this.onKeyDown.bind(this)
    this.onPointerDown = this.onPointerDown.bind(this)
    this.onPointerMove = this.onPointerMove.bind(this)
    this.onPointerUp = this.onPointerUp.bind(this)

    // First fit & save scale
    requestAnimationFrame(() => {
      this.scale = zoomToFit(this.diagramTarget, this.courtTarget)
    })

    // On resize, update scale
    this.handleResize = () => {
      this.scale = zoomToFit(this.diagramTarget, this.courtTarget)
    }
    
    // Add listeners
    this.diagramTarget.addEventListener('click', this.onClick)
    this.diagramTarget.addEventListener('dblclick', this.onDblClick)
    this.diagramTarget.addEventListener('pointerdown', this.onPointerDown)
    window.addEventListener('resize', this.handleResize)
    window.addEventListener('pointermove', this.onPointerMove)
    window.addEventListener('pointerup', this.onPointerUp)
    window.addEventListener("keydown", this.onKeyDown.bind(this))
  }

  currentViewBox() {
    const vb = this.diagramTarget.viewBox.baseVal
    return { width: vb.width, height: vb.height }
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

  initialize() {
    this.mode = 'idle'
    const { attackers, defenders } = parseDiagramContent(this.diagramTarget)
    this.attackerNumbers = attackers
    this.defenderNumbers = defenders
    this.courtBox = this.courtTarget.getBBox()  // <- returns {x, y, width, height}
    DEBUG && console.log("Court viewBox:", this.courtBox)
  }

  // --- [2] SVG object creation ---
  addAttacker(event) { this.addObject(event, "attacker", this.attackerNumbers) }
  addBall(event)     { this.addObject(event, "ball") }
  addCoach(event) { this.addObject(event, "coach") }
  addCone(event)     { this.addObject(event, "cone", null, 0.07) }
  addDefender(event) { this.addObject(event, "defender", this.defenderNumbers) }

  addObject(event, kind, set = null) {
    const button = event.currentTarget
    const svg = button.querySelector("svg[data-symbol-id]")
    const symbolId = svg?.dataset.symbolId
    if (!symbolId) {
      DEBUG && console.warn("button has not symbolId: ", button)
      return
    }
    
    const number = set ? findLowestAvailableNumber(set) : null
    if (number) set.add(number)

    // Proceed to add the object with necessary attributes
    return createSymbol(this.diagramTarget, symbolId, kind, number)
  }

  // --- [4] Line drawing functions ---
  startDrawing(evt) {
    const button = evt.currentTarget

    // If clicking the same button, toggle drawing mode off
    if (this.mode === "drawing" && this.activeLineButton === button) {
      this.stopDrawing()
      return
    }

    // Highlight only current button
    this.clearActiveLineButtons()
    const activeClass = button.dataset.activeClass || "bg-blue-600 text-white ring"
    button.classList.add(...activeClass.split(" "))

    // prepare metadata
    this.curve  = button.dataset.curve || true
    this.style  = button.dataset.style || "solid"
    this.ending = button.dataset.ending || "arrow"  // default arrowhead endings

    // Initialize empty preview group for visual feedback
    this.points = []
    this.tempPath = prepareTempPath(this.points, button.dataset)  // setup  the temporary editable group

    this.mode = 'drawing'
    this.activeLineButton = button
  }

  enterEditMode(group) {
    this.mode = 'editing'
    this.editingGroup = group
    this.originalPoints = JSON.parse(group.dataset.points)
    this.points = [...this.originalPoints]

    // Set existing points and styling on the preview path
    this.curve  = group.dataset.curve
    this.style  = group.dataset.style
    this.ending = group.dataset.ending
    this.tempPath = prepareTempPath(this.points, group.dataset)  // setup  the temporary editable group
    group.remove()  // Remove the original group from canvas (store it temporarily)
    this.showHandles()
  }

  exitEditMode(restore = false) {
    if (restore) {
      // Revert to original points
      this.points = [...this.originalPoints]
      updatePath(this.editingGroup, this.points)
      this.diagramTarget.appendChild(this.editingGroup)
      this.tempGroup?.remove()
    } else {
      // Finalize the tempGroup by transferring styling and points to editingGroup
      if (this.editingGroup && this.tempGroup) {
        updatePath(this.editingGroup, this.points)
        this.editingGroup.classList.add("line-group", "draggable")
        this.editingGroup.dataset.points = JSON.stringify(this.points)
        this.editingGroup.dataset.pathType = this.lineShape
        this.editingGroup.dataset.type = this.lineStyle
        this.editingGroup.dataset.ending = this.lineEnding
        this.editingGroup.dataset.kind = this.lineType
        this.diagramTarget.appendChild(this.editingGroup)
        this.tempGroup?.remove()
      }
    }

    this.editingGroup = null
    this.originalPoints = null
    this.stopDrawing()
  }

  finalizeDrawing() {
    if (this.points.length < 2) return this.stopDrawing()

    if (this.tempGroup) {
      const newLine = createPath(this.points, {curve: this.curve, style: this.style, ending: this.ending})
      this.diagramTarget.appendChild(newLine)

      this.tempGroup = null
      this.tempPath = null
    }

    this.stopDrawing()
  }

  stopDrawing() {
    if (this.tempGroup) {
      this.tempGroup.remove()
      this.tempGroup = null
    }
    this.tempPath = null
    this.points = []
    this.mode = "idle"
    this.clearActiveLineButtons()
    this.activeLineButton = null
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

    const inner = getInnerElement(wrapper)
    if (!inner) {
      DEBUG && console.warn("No inner object to delete inside wrapper")
      return
    }

    const kind = inner.getAttribute('kind') || inner.dataset.kind
    DEBUG && console.warn("inner object:", inner)

    if ((kind === "attacker") || (kind === "defender")) {
      const number = getObjectNumber(inner)
      if (number) {
        DEBUG && console.log(`Removing ${kind} number ${number}`)
        kind === 'attacker' 
          ? this.attackerNumbers.delete(number)
          : this.defenderNumbers.delete(number)
      }
    }

    wrapper.classList.add('opacity-0', 'transition-opacity', 'duration-300')
    setTimeout(() => {
      wrapper.remove()
      this.selectedElement = null
      this.deleteButtonTarget.disabled = true
    }, 300)
  }

  handleSelection(evt) {
    const wrapper = evt.target.closest('g.wrapper')
    this.clearSelection() // Deselect previous element, if any

    if (wrapper) {  // Select the new group and highlight it
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
    if (this.isDrawing())  {
      const pt = getPointFromEvent(evt, this.diagramTarget)
      this.points.push(pt)
      updatePath(this.tempGroup, this.points)
    } else if (this.mode === 'editing') {
      // Editing logic if any
    } else {
      this.handleSelection(evt)
    }
  }

  onDblClick(evt) {
    const target = evt.target

    if (this.isDrawing()) {
      this.finalizeDrawing()
      return
    } else if (this.isIdle()) {
      const lineGroup = target.closest('g.line-group')
      if (lineGroup) {
        if (!this.isEditing()) {  // Prevent multiple edit modes
          this.enterEditMode(lineGroup)
        }
      }
    } else if (this.isEditing()) {
      const isHandle = target.classList.contains('handle')
      const isFinalPoint = target.dataset.pointIndex === `${this.points.length - 1}`
      if (isHandle && isFinalPoint) {
        this.exitEditMode()
      }
    }
  }

  onKeyDown(evt) {
    if (evt.key !== 'Escape') return

    if (this.isEditing()) {
      this.exitEditMode(true) // restore edited content
    } else if (this.isDrawing()) {
      this.stopDrawing() // discard changes
    } else {  //idle mode -- deselect selected object
      this.clearSelection()
    }
  }

  onPointerDown(evt) {
    if (this.isInDrawingOrEditing()) return // Disable object interactions if drawing/editing

    if (evt.target.classList.contains('handle')) {
      this.handleStart(evt)  // Acquire object handle
    } else {
      this.dragStart(evt);  // Start dragging object
    }
  }

  onPointerMove(evt) {
    if (this.isInDrawingOrEditing()) return // Disable object dragging if drawing/editing

    if (this.handleIndex !== null) {
      this.handleDrag(evt)  // Move handle position
    } else {
      this.drag(evt)  // Move a regular object
    }
  }

  onPointerUp(evt) {
    if (this.handleIndex !== null) {
      this.handleEnd() // Manage editing
    } else if (this.draggedWrapper) {
      this.dragEnd(evt)   // Complete the object dragging
    }
  }

  // Helper methods to check current mode
  isDrawing() {
    return this.mode === 'drawing'
  }

  isEditing() {
    return this.mode === 'editing'
  }

  isIdle() {
    return this.mode === 'idle'
  }

  isInDrawingOrEditing() {
    return this.isDrawing() || this.isEditing()
  }

  // Creates handles at each point of the path
  createHandles() {
    // Clear any existing handles before adding new ones
    this.clearHandles()

    // Create handles at each point along the path
    this.points.forEach((pt, index) => {
      const handle = createHandle(pt, index)  // Create a handle at the point
      this.diagramTarget.appendChild(handle)  // Add the handle to the canvas
      this.handles.push(handle)  // Store the handle for later reference
    })
  }

  showHandles() {
    this.handles = []
    this.points.forEach((pt, index) => {
      const handle = createHandle(pt, index)
      this.diagramTarget.appendChild(handle)
      this.handles.push(handle)
    })
  }

  clearHandles() {
    if (!this.handles) return
    this.handles.forEach(h => h.remove())
    this.handles = []
  }

  handleDrag(evt) {
    const pt = getPointFromEvent(evt, this.diagramTarget)
    this.points[this.handleIndex] = pt
    updatePath(this.editingGroup, this.points)
    this.updateHandles(this.handles, this.points)
  }

  handleStart(evt) {
    this.handleIndex = parseInt(evt.target.dataset.pointIndex, 10)
  }

  handleEnd() {
    this.handleIndex = null
  }

  // Updates the position of the handles based on the new points
  updateHandles() {
    this.handles.forEach((handle, index) => {
      const pt = this.points[index]  // Get the updated point
      handle.setAttribute('cx', pt.x)  // Update the x position of the handle
      handle.setAttribute('cy', pt.y)  // Update the y position of the handle
    })
  }

  // Dragging
  dragStart(evt) {
    const wrapper = evt.target.closest('g.wrapper')
    if (!wrapper) return
    this.draggedWrapper = wrapper

    const inner = getInnerElement(wrapper)
    if (!inner) return
    this.draggedInner = inner

    DEBUG && console.log("dragStart: ", wrapper.getAttribute("id"), "inner: ", inner.getAttribute("id"))
    DEBUG && console.log("coordinates: [", inner.getAttribute("y"), ", ", inner.getAttribute("y"), "]")
    document.body.style.cursor = 'grabbing'
    evt.preventDefault()
  }

  drag(evt) {
    if (!this.draggedInner) return

    // Track current position using SVG coordinates
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
    this.draggedInner.dataset.x = pt.x
    this.draggedInner.dataset.y = pt.y

    // Re-apply visual transform (scale only) to wrapper
    setVisualTransform(this.draggedWrapper, { x: pt.x, y: pt.y, scale: null })
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