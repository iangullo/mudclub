// app/javascript/controllers/diagram_editor_controller.js
import { Controller } from "@hotwired/stimulus"
import {
  cloneSVGElement,
  createGroup,
  createHandle,
  createSVGElement,
  deserializeGroup,
  fetchSvgText,
  parseSvg,
  serializeGroup,
  toSvgPoint,
  updateLabel,
  updatePath,
  zoomToFit
} from "helpers/svg_helper"

export default class extends Controller {
  static targets = ["canvas", "output", "deleteButton"]

  // --- [1] editor startup functions ---
  connect() {
    this.setCanvas()
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

    // Add listeners
    this.canvasTarget.addEventListener('click', this.onClick)
    this.canvasTarget.addEventListener('dblclick', this.onDblClick)
    this.canvasTarget.addEventListener('pointerdown', this.onPointerDown)
    window.addEventListener('pointermove', this.onPointerMove)
    window.addEventListener('pointerup', this.onPointerUp)
    window.addEventListener("keydown", this.onKeyDown.bind(this))
  }

  currentViewBox() {
    const vb = this.canvasTarget.viewBox.baseVal
    return { width: vb.width, height: vb.height }
  }

  disconnect() {
    this.canvasTarget.removeEventListener('click', this.onClick)
    this.canvasTarget.removeEventListener('dblclick', this.onDblClick)
    this.canvasTarget.removeEventListener('pointerdown', this.onPointerDown)
    window.removeEventListener('pointermove', this.onPointerMove)
    window.removeEventListener('pointerup', this.onPointerUp)
    window.removeEventListener('keydown', this.onKeyDown)
  }

  initialize() {
    this.mode = 'idle'
    this.attackerNumbers = new Set()
    this.defenderNumbers = new Set()
    this.loadDiagram()
  }

  loadDiagram() {
    const storedSvg = this.outputTarget.value
    if (storedSvg) {
      const items = JSON.parse(storedSvg)
      items.forEach(item => {
        const el = deserializeGroup(item, this.canvasTarget)
        if (el) this.canvasTarget.appendChild(el)
      })
    }
  }

  serialize() {
    const groups = Array.from(this.canvasTarget.querySelectorAll("g.draggable"))
    const serialized = groups
      .map(g => serializeGroup(g))
      .filter(entry => entry !== null)

    const viewBox = this.canvasTarget.getAttribute("viewBox") || null

    const diagramData = {
      viewBox,
      elements: serialized
    }

    if (this.hasOutputTarget) {
      this.outputTarget.value = JSON.stringify(diagramData)
      //console.log("outputTarget: ", this.outputTarget)
    }
  }

  setCanvas() {
    const svg = this.canvasTarget
    //console.log("canvasTarget:", svg)
    const imageElement = svg.querySelector("image")
    //console.log("imageElement:", imageElement)

    if (!svg || !imageElement || !imageElement.hasAttribute("href")) return
    const href = imageElement.getAttribute("href")
    //console.log("canvas image href:", href)

    const img = new Image()
    img.onload = () => {
      zoomToFit(svg, img)
    }
    img.src = href
  }

  // --- [2] SVG object creation ---
  addAttacker(event) { this.addObject(event, "attacker", this.attackerNumbers) }
  addBall(event)     { this.addObject(event, "ball") }
  addCoach(event) { this.addObject(event, "coach") }
  addCone(event)     { this.addObject(event, "cone", null, 0.07) }
  addDefender(event) { this.addObject(event, "defender", this.defenderNumbers) }

  addObject(event, type, set = null, scale = 0.06) {
    const number = set ? this.findLowestFreeNumber(set) : null
    if (number) set.add(number)

    // Proceed to add the object with necessary attributes
    this.createSvgObject({ event, type, scale, label: number })
  }

  // mark it async so you can await
  async createSvgObject({ event, type, scale = 0.05, label = null }) {
    const { width, height } = this.currentViewBox()
    const size = width * scale
    const x0 = width * 0.2
    const y0 = height * 0.3

    const button = event.currentTarget
    console.warn("button content: ", button)
    let inlineSvg

    // 1) “Real” inline SVG?
    const svgSourceEl = button.querySelector("svg")
    if (svgSourceEl) {
      inlineSvg = svgSourceEl
    }

    // 2) Otherwise, look for an <img> whose src is an SVG URL and fetch+parse it
    if (!inlineSvg) {
      const img = button.querySelector("img")
      if (img && img.src && img.src.endsWith(".svg")) {
        try {
          const text = await fetchSvgText(img.src)
          if (text) inlineSvg = parseSvg(text)
        } catch (e) {
          console.warn("Could not fetch/parse SVG from img.src", e)
        }
      }
    }

    // 3) If still nothing, bail out
    if (!inlineSvg) {
      console.warn("No inline <svg> and could not fetch an SVG to clone.")
      return
    }

    // Clone + size
    console.warn("cloning inlineSvg: ", inlineSvg)
    const clonedElement = cloneSVGElement(inlineSvg, size)
    if (!clonedElement) return
    if (label != null) updateLabel(clonedElement, label)
    console.warn("clonedElement: ", clonedElement)

    // Wrap in draggable group
    const group = createGroup(x0, y0)
    group.dataset.type = "object"
    group.dataset.role = type
    group.dataset.label = label
    group.appendChild(clonedElement)
    this.canvasTarget.appendChild(group)
    this.serialize()
  }

  findLowestFreeNumber(set) {
    let i = 1
    while (set.has(i)) {
      i++
    }
    return i
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

    // Store metadata
    this.lineShape = button.dataset.lineShape || "bezier"
    this.lineStyle = button.dataset.lineStyle || "solid"
    this.lineEnding = button.dataset.lineEnding || "arrow"  // default arrowhead endings
    this.lineType   = button.dataset.object || "generic"

    // Initialize empty preview group for visual feedback
    this.points = []
    this.prepareTempPathGroup([])

    this.mode = 'drawing'
    this.activeLineButton = button
  }

  enterEditMode(group) {
    this.mode = 'editing'
    this.editingGroup = group
    this.originalPoints = JSON.parse(group.dataset.points)
    this.points = [...this.originalPoints]

    // Set existing points and styling on the preview path
    this.lineShape  = group.dataset.pathType
    this.lineStyle  = group.dataset.style
    this.lineEnding = group.dataset.ending
    this.lineType   = group.dataset.role
    this.prepareTempPathGroup(this.points)  // setup  the temporary editable group
    group.remove()  // Remove the original group from canvas (store it temporarily)
    this.showHandles()
  }

  exitEditMode(restore = false) {
    if (restore) {
      // Revert to original points
      this.points = [...this.originalPoints]
      updatePath(this.editingGroup, this.points)
      this.canvasTarget.appendChild(this.editingGroup)
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
        this.editingGroup.dataset.role = this.lineType
        this.canvasTarget.appendChild(this.editingGroup)
        this.tempGroup?.remove()
        this.serialize()
      }
    }

    this.editingGroup = null
    this.originalPoints = null
    this.stopDrawing()
  }

  finalizeDrawing() {
    if (this.points.length < 2) return this.stopDrawing()

    if (this.tempGroup) {
      const group = this.tempGroup

      group.classList.remove("line-preview", "opacity-50", "pointer-events-none")
      group.classList.add("line-group", "draggable")
      group.dataset.points = JSON.stringify(this.points)
      group.dataset.pathType = this.lineShape
      group.dataset.type = this.lineStyle
      group.dataset.ending = this.lineEnding
      group.dataset.role = this.lineType

      this.canvasTarget.appendChild(group)
      this.tempGroup = null
      this.tempPath = null
    }

    this.stopDrawing()
    this.serialize()
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
      console.log("clearSelection: ", this.selectedElement)
      this.lowlightElement(this.selectedElement)
      const prev = this.selectedElement.querySelector('.selection-indicator')
      if (prev) prev.remove()
        this.selectedElement = null
    }
    this.deleteButtonTarget.disabled = true
  }

  deleteSelected() {
    console.log("deleteSelected: ", this.selectedElement)
    const selected = this.selectedElement
    if (!selected) return

    // Check the selected element itself first
    let dataElement = selected
    if (!dataElement.dataset.role && !dataElement.dataset.type) {
      // If not present, search descendants
      dataElement = selected.querySelector('[data-type], [data-role]')
    }

    console.log("dataElement: ", dataElement)

    if (dataElement) {
      const type = dataElement.dataset.role || dataElement.dataset.type
      const number = parseInt(dataElement.dataset.label)
      console.log("type: ", type, "; number:", number)

      if (type === "attacker") {
        this.attackerNumbers.delete(number)
        console.log("attackerNumbers: ", this.attackerNumbers)
      } else if (type === "defender") {
        this.defenderNumbers.delete(number)
        console.log("defenderNumbers: ", this.defenderNumbers)
      }
    }

    this.selectedElement.classList.add('opacity-0', 'transition-opacity', 'duration-300')
    setTimeout(() => {
      this.selectedElement.remove()
      this.selectedElement = null
      this.deleteButtonTarget.disabled = true
      this.serialize()
    }, 300)
  }

  handleSelection(evt) {
    const grp = evt.target.closest('g.draggable, path.draggable')
    this.clearSelection() // Deselect previous element, if any
    if (grp) {  // Select the new group and highlight it
      this.selectedElement = grp
      this.deleteButtonTarget.disabled = false
      this.highlightElement(grp)
      console.log("this.selectedElement: ", this.selectedElement)
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

  prepareTempPathGroup(points = []) {
    const group = createGroup(points[0]?.x || 0, points[0]?.y || 0) // creates <g draggable>
    group.dataset.type = "path"
    group.dataset.pathType = this.lineShape
    group.dataset.style = this.lineStyle
    group.dataset.ending = this.lineEnding
    group.dataset.role = this.lineType
    group.classList.add(
      "line-preview",
      "opacity-50",
      "stroke-gray-400",
      "stroke-dashed",
      "stroke-2",
      "pointer-events-none"
    )

    const path = createSVGElement("path")
    path.classList.add("preview-path")
    group.appendChild(path)

    this.tempGroup = group
    this.tempPath = path

    updatePath(group, points)
    this.canvasTarget.appendChild(group)
  }

  onClick(evt) {
    if (this.isDrawing())  {
      const pt = toSvgPoint(evt, this.canvasTarget)
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
    } else if (this.draggedElement) {
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
      this.canvasTarget.appendChild(handle)  // Add the handle to the canvas
      this.handles.push(handle)  // Store the handle for later reference
    })
  }

  showHandles() {
    this.handles = []
    this.points.forEach((pt, index) => {
      const handle = createHandle(pt, index)
      this.canvasTarget.appendChild(handle)
      this.handles.push(handle)
    })
  }

  clearHandles() {
    if (!this.handles) return
    this.handles.forEach(h => h.remove())
    this.handles = []
  }

  handleDrag(evt) {
    const pt = toSvgPoint(evt, this.canvasTarget)
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

  // Drag & select
  dragStart(evt) {
    const t = evt.target.closest('g.draggable, path.draggable')
    if (!t) return
    this.draggedElement = t
    const pt = toSvgPoint(evt, this.canvasTarget)
    const baseTransform = t.transform.baseVal
    const tr = baseTransform.numberOfItems ? baseTransform.consolidate() : null
    const m = tr ? tr.matrix : this.canvasTarget.createSVGMatrix()
    this.offset = { x: pt.x - m.e, y: pt.y - m.f }
    evt.preventDefault()
  }

  drag(evt) {
    if (!this.draggedElement) return
    const pt = toSvgPoint(evt, this.canvasTarget)
    const x = pt.x - this.offset.x, y = pt.y - this.offset.y
    this.draggedElement.setAttribute('transform', `translate(${x},${y})`)
    evt.preventDefault()
  }

  dragEnd() {
    this.draggedElement = null
    this.serialize()
  }
}