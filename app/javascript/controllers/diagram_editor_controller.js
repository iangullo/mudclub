// app/stimulus/controllers/diagram_editor_controller.js
// Developed with significant help from DeepSeek
// Attempt at a responsive and dynamic diagram editor.
import { Controller } from '@hotwired/stimulus'
import { loadDiagramContent, findLowestAvailableNumber, zoomToFit } from 'helpers/svg_loader'
import { applyPathColor, createPath, updatePath, MIN_POINTS_FOR_CURVE } from 'helpers/svg_paths'
import { serializeDiagram } from 'helpers/svg_serializer'
import { applySymbolColor, createSymbol, getObjectNumber, isPlayer, SYMBOL_SIZE } from 'helpers/svg_symbols'
import { findElementNearPoint, getPointFromEvent, getInnerGroup, highlightElement, lowlightElement, updatePosition } from 'helpers/svg_utils'

const SYMBOL_PREVIEW_OPACITY = 0.7
const SYMBOL_PLACEMENT_DURATION = 300
const DEBUG = false

export default class extends Controller {
  static targets = ['diagram', 'court', 'svgdata', 'deleteButton', 'colorButton', 'colorMenu']

  // --- Initialization ---
  connect() {
    this.setupEventListeners()
    this.resetDrawingState()
    requestAnimationFrame(() => {
      this.scale = zoomToFit(this.diagramTarget, this.courtTarget, true)
    })
  }

  disconnect() {
    this.unbindWindowEvents()
    this.unbindDiagramEvents()
  }

  initialize() {
    this.initializeState()
    this.initializeDiagramContent()
  }

  initializeDiagramContent() {
    const { attackers, defenders } = loadDiagramContent(this.diagramTarget, this.svgdataTarget.value, true)
    this.attackerNumbers = attackers
    this.defenderNumbers = defenders
    this.courtBox = this.courtTarget.getBBox()
  }

  initializeState() {
    this.mode = 'idle'
    this.selectedElement = null
    this.draggedElement = null
    this.colorMenuElement = null
    this.editingPathPoints = false
    this.editingPath = null
    this.draggedPointIndex = null
    this.originalPoints = null
    this.disableOptButtons()
  }

  // --- Binding/Unbinding of events ---
  setupEventListeners() {
    this.bindWindowEvents()
    this.bindDiagramEvents()
  }

  bindWindowEvents() {
    this.handleResize = () => {
      this.scale = zoomToFit(this.diagramTarget, this.courtTarget, true)
    }

    window.addEventListener('resize', this.handleResize)
    window.addEventListener('pointermove', this.onPointerMove.bind(this))
    window.addEventListener('pointerup', this.onPointerUp.bind(this))
    window.addEventListener('keydown', this.onKeyDown.bind(this))
  }

  bindDiagramEvents() {
    this.diagramTarget.addEventListener('click', this.onClick.bind(this))
    this.diagramTarget.addEventListener('dblclick', this.onDblClick.bind(this))
    this.diagramTarget.addEventListener('pointerdown', this.onPointerDown.bind(this))
  }

  unbindWindowEvents() {
    window.removeEventListener('resize', this.handleResize)
    window.removeEventListener('pointermove', this.onPointerMove)
    window.removeEventListener('pointerup', this.onPointerUp)
    window.removeEventListener('keydown', this.onKeyDown)
  }

  unbindDiagramEvents() {
    this.diagramTarget.removeEventListener('click', this.onClick)
    this.diagramTarget.removeEventListener('dblclick', this.onDblClick)
    this.diagramTarget.removeEventListener('pointerdown', this.onPointerDown)
  }

  // --- Event Management ---

  // Dragging of symbols/points
  drag(evt) {
    if (!this.draggedInner) return

    const pt = getPointFromEvent(evt, this.diagramTarget)
    DEBUG && console.log('drag([', pt.x, ', ', pt.y, '])')

    const { x: minX, y: minY, width, height } = this.courtBox
    const maxX = minX + width - 3 * SYMBOL_SIZE
    const maxY = minY + height - 3 * SYMBOL_SIZE
    // Bail out if outside allowed area (based on logical coords)
    if (pt.x < minX || pt.x > maxX || pt.y < minY || pt.y > maxY) {
      DEBUG && console.log('Blocked drag outside court:', pt.x, pt.y)
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
      DEBUG && console.log('dragEnd:', this.draggedWrapper.id, 'coords:', x, y)
    }
    this.draggedWrapper = null
    this.draggedInner = null
  }

  dragStart(evt) {
    const wrapper = evt.target.closest('g.wrapper')
    if (!wrapper) return

    this.draggedWrapper = wrapper
    this.draggedType = wrapper.getAttribute('type') || 'symbol'
    if (this.draggedType != 'symbol') return

    const inner = getInnerGroup(wrapper)
    if (!inner) return
    this.draggedInner = inner

    if (DEBUG) {
      console.log('dragStart: ', wrapper.getAttribute('id'), 'inner: ', inner.getAttribute('id'))
      console.log('coordinates: [', inner.getAttribute('y'), ', ', inner.getAttribute('y'), ']')
    }
    document.body.style.cursor = 'grabbing'
    evt.preventDefault()
  }

  // Selection of objects
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
      highlightElement(wrapper)
      this.enableOptButtons()

      if (DEBUG) {
        const inner = getInnerGroup(wrapper)
        console.log('Selected:', {
          wrapper: wrapper.id,
          kind: inner?.dataset.kind,
          number: inner ? getObjectNumber(inner) : null
        })
      }
    }
  }

  // pointer actions
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
          this.hideColorMenu()
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

  // --- SVG symbol management ---
  addAttacker(evt) { this.addObject(evt, 'attacker', this.attackerNumbers) }
  addBall(evt) { this.addObject(evt, 'ball') }
  addCoach(evt) { this.addObject(evt, 'coach') }
  addCone(evt) { this.addObject(evt, 'cone', null, 0.07) }
  addDefender(evt) { this.addObject(evt, 'defender', this.defenderNumbers) }

  addObject(evt, kind, set = null) {
    const button = evt.currentTarget
    const svg = button.querySelector('svg[data-symbol-id]')
    const symbolId = svg?.dataset.symbolId
    if (!symbolId) {
      DEBUG && console.warn('button has no symbolId: ', button)
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
      { symbol_id: symbolId, kind: kind, label: number },
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

  handlePlacementMove = (evt) => {
    if (!this.placementSymbol) return

    const point = getPointFromEvent(evt, this.diagramTarget)
    const inner = getInnerGroup(this.placementSymbol)

    if (inner) {
      // Update position with smooth transition
      inner.style.transition = 'transform 0.1s ease-out'
      updatePosition(inner, point.x, point.y)
    }
  }

  handlePlacementClick = (evt) => {
    if (!this.placementSymbol) return

    const point = getPointFromEvent(evt, this.diagramTarget)
    const inner = getInnerGroup(this.placementSymbol)

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

  deleteSymbolCounter(wrapper) {
    DEBUG && console.warn('deleteSymbolCounter(', wrapper, ')')
    const player = isPlayer(wrapper)
    if (player) {
      const kind = player.kind
      const number = player.number
      DEBUG && console.log(`Removing ${kind} number ${number}`)
      kind === 'attacker'
        ? this.attackerNumbers.delete(number)
        : this.defenderNumbers.delete(number)
    }
  }

  // --- SVG path management ---
  startDrawing(evt) {
    const button = evt.currentTarget
    DEBUG && console.log('startDrawing ', button)

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
    DEBUG && console.log('drawingParams ', this.drawingParams)
    this.tempPath = createPath(this.drawingPoints, this.drawingParams)
    this.diagramTarget.appendChild(this.tempPath)

    // Store reference to the actual path element
    this.tempPathGroup = this.tempPath.querySelector('g')
  }

  addDrawingPoint(evt) {
    if (this.mode !== 'drawing') return
    this.drawingParams.scale = this.scale
    const point = getPointFromEvent(evt, this.diagramTarget)

    // Skip duplicate points (within 1px tolerance)
    if (this.drawingPoints.length > 2) {
      const lastPoint = this.drawingPoints[this.drawingPoints.length - 1]
      const dx = point.x - lastPoint.x
      const dy = point.y - lastPoint.y
      const distanceSquared = dx * dx + dy * dy

      if (distanceSquared < 1) {  // 1px² tolerance
        DEBUG && console.log('Skipping duplicate point', point)
        return
      }
    }

    DEBUG && console.log('addDrawingPoint ', point)
    this.drawingPoints.push(point)

    // Update the path with the new fixed point
    if (!this.drawingParams.curve && this.drawingPoints.length === 2) {
      this.finalizeDrawing()
    } else if (this.drawingPoints.length >= 2) {
      updatePath(this.tempPathGroup, this.drawingPoints, this.drawingParams)
    }
  }

  trackDrawingPointer(evt) {
    if (this.mode !== 'drawing' || this.drawingPoints.length === 0) return

    requestAnimationFrame(() => {
      this.currentPoint = getPointFromEvent(evt, this.diagramTarget)
      const tempPoints = [...this.drawingPoints, this.currentPoint]
      updatePath(this.tempPathGroup, tempPoints, this.drawingParams)
    })
  }

  finalizeDrawing() {
    DEBUG && console.log('finalizeDrawing()')
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
    DEBUG && console.log('stopDrawing()')
    this.currentPoint = null
    this.resetDrawingState()
    if (this.tempPath) {
      this.diagramTarget.removeChild(this.tempPath)
      this.tempPath = null
    }
    this.activeDrawingButton = null
  }

  resetDrawingState(mode = 'idle') {
    DEBUG && console.log('resetDrawingState()')
    this.unhighlightButton(this.activeDrawingButton)
    this.drawingPoints = []
    this.drawingParams = {}
    this.currentPoint = null
    this.mode = mode
  }

  // --- SVG object selection & removal ---
  clearSelection() {
    if (this.selectedElement) {
      DEBUG && console.log('clearSelection: ', this.selectedElement)
      lowlightElement(this.selectedElement)
      const indicator = this.selectedElement.querySelector('.selection-indicator')
      if (indicator) indicator.remove()

      this.selectedElement = null
    }
    this.disableOptButtons()
  }

  deleteSelected() {
    const wrapper = this.selectedElement
    if (!wrapper) return

    this.disableOptButtons()
    this.deleteSymbolCounter(wrapper)
    wrapper.classList.add('opacity-0', 'transition-opacity', 'duration-300')
    setTimeout(() => {
      wrapper.remove()
      this.selectedElement = null
    }, 300)
  }

  getSelectionTolerance() {
    return SELECTION_TOLERANCE / this.scale
  }

  // --- Auxiliary diagram helpers ---
  clearActiveLineButtons() {
    const buttons = this.element.querySelectorAll("[data-action*='startDrawing']")
    buttons.forEach(btn => {
      const activeClass = btn.dataset.activeClass || ''
      btn.classList.remove(...activeClass.split(' '))
    })
  }

  disableButton(buttonTarget) {
    const button = this.getButtonElement(buttonTarget)
    if (button) {
      button.disabled = true
      button.classList.add('opacity-50', 'cursor-not-allowed')
    }
  }

  disableOptButtons() {
    this.disableButton(this.deleteButtonTarget)
    this.disableButton(this.colorButtonTarget)
  }

  enableButton(buttonTarget) {
    const button = this.getButtonElement(buttonTarget)
    if (button) {
      button.disabled = false
      button.classList.remove('opacity-50', 'cursor-not-allowed')
    }
  }

  enableOptButtons() {
    DEBUG && console.log('showOptButtons()')
    this.enableButton(this.deleteButtonTarget)
    const type = this.selectedElement.getAttribute('type')
    if (type === 'path' || type === 'symbol') {
      this.enableButton(this.colorButtonTarget)
    }
  }

  getButtonElement(target) {
    // If the target is already a button, return it
    if (target.tagName === 'BUTTON') return target

    // Otherwise, look for a button within the target
    return target.querySelector('button')
  }

  highlightButton(button) {
    DEBUG && console.log('highlighButton()')
    if (!button) return
    const activeClass = button.dataset.activeClass || 'bg-blue-400 text-white ring'
    button.classList.add(...activeClass.split(' '))
  }

  isDrawing() {
    return this.mode === 'drawing'
  }

  isIdle() {
    return this.mode === 'idle'
  }

  unhighlightButton(button) {
    DEBUG && console.log('unhighlighButton()')
    if (!button) return
    const activeClass = button.dataset.activeClass || ''
    button.classList.remove(...activeClass.split(' '))
  }

  // --- COLOR MANAGEMENT ---/
  applyColor(evt) {
    evt.preventDefault()
    evt.stopPropagation()

    const color = evt.currentTarget.dataset.color
    if (!this.selectedElement || !color) return

    // Apply color to the selected element
    const inner = getInnerGroup(this.selectedElement)
    if (inner) {
      // Check if it's a path or symbol
      if (this.selectedElement.getAttribute('type') === 'path') {
        applyPathColor(inner, color)
      } else {
        applySymbolColor(inner, color)
      }
    }

    // Hide the menu after selection
    this.hideColorMenu()
  }

  colorMenu(evt) {
    evt.preventDefault()
    evt.stopPropagation()

    // Position the menu near the color button
    const rect = this.colorButtonTarget.getBoundingClientRect()
    this.colorMenuTarget.style.top = `${rect.bottom + window.scrollY}px`
    this.colorMenuTarget.style.left = `${rect.left + window.scrollX}px`

    // Show the menu
    this.colorMenuTarget.classList.remove('hidden')

    // Add event listeners to handle clicks outside and Escape key
    this.boundHideColorMenu = this.hideColorMenu.bind(this)
    document.addEventListener('click', this.boundHideColorMenu)
  }

  hideColorMenu(evt) {
    // Don't hide if clicking on the color button or menu itself
    if (evt && (
      this.colorButtonTarget.contains(evt.target) ||
      this.colorMenuTarget.contains(evt.target)
    )) {
      return
    }

    this.colorMenuTarget.classList.add('hidden')
    document.removeEventListener('click', this.boundHideColorMenu)
  }

  // --- [END] SERIALIZE CONTENT ---/
  serialize() {
    const data = serializeDiagram(this.diagramTarget)
    this.svgdataTarget.value = JSON.stringify(data)
    DEBUG && console.log('Serialized data:', data)
  }
}