// app/stimulus/controllers/diagram_editor_controller.js
// Developed with significant help from DeepSeek
// Attempt at a responsive and dynamic diagram editor.
import { Controller } from '@hotwired/stimulus'
import { disableButtons, enableButtons, highlightButton, lowlightButton } from 'helpers/svg_buttons'
import { loadDiagramContent, findLowestAvailableNumber, zoomToFit } from 'helpers/svg_loader'
import { applyPathColor, createPath, getPathOptions, getPathPoints, setPathEditMode, updatePath, MIN_POINTS_FOR_CURVE } from 'helpers/svg_paths'
import { serializeDiagram } from 'helpers/svg_serializer'
import { applySymbolColor, createSymbol, getObjectNumber, isPlayer, SYMBOL_SIZE } from 'helpers/svg_symbols'
import { debounce, findNearbyObject, getPointFromEvent, highlightElement, lowlightElement, updatePosition } from 'helpers/svg_utils'

const MODE = {
  DRAW: 'draw',
  DRAG: 'drag',
  DRAG_POINT: 'drag_point',
  EDIT: 'edit',
  IDLE: 'idle',
  PLACE: 'place',
  SELECT: 'select'
}
const SYMBOL_PREVIEW_OPACITY = 0.7
const SYMBOL_PLACEMENT_DURATION = 300
const DEBUG = false

export default class extends Controller {
  static targets = ['diagram', 'court', 'svgdata', 'colorMenu', // content
    'attackerButton', 'ballButton', 'coachButton', 'colorButton', // buttons
    'coneButton', 'defenderButton', 'deleteButton', 'dribbleButton',
    'handoffButton', 'moveButton', 'passButton', 'pickButton', 'shotButton'
  ]

  // --- Initialization ---
  connect() {
    this.setupEventListeners()
    this.resetDrawingState()
    this.zoomAfterRender()
  }

  disconnect() {
    this.unbindWindowEvents()
    this.unbindDiagramEvents()
  }

  initialize() {
    this.initializeState()
    this.initializeDiagram()
  }

  initializeDiagram() {
    const { attackers, defenders } = loadDiagramContent(this.diagramTarget, this.svgdataTarget.value, true)
    this.attackerNumbers = attackers
    this.defenderNumbers = defenders
    this.courtBox = this.courtTarget.getBBox()
  }

  initializeState() {
    this.selectedObject = null
    this.draggedElement = null
    this.colorMenuElement = null
    this.tempPath = null
    this.draggedPoint = null
    this.draggedPointIndex = -1
    this.draggedPath = null

    // button groups
    this.allButtons = [
      this.attackerButtonTarget, this.ballButtonTarget, this.coachButtonTarget,
      this.colorButtonTarget, this.coneButtonTarget, this.defenderButtonTarget,
      this.deleteButtonTarget, this.dribbleButtonTarget, this.handoffButtonTarget,
      this.moveButtonTarget, this.passButtonTarget, this.pickButtonTarget,
      this.shotButtonTarget
    ]
    this.idleButtons = [
      this.attackerButtonTarget, this.ballButtonTarget, this.coachButtonTarget,
      this.coneButtonTarget, this.defenderButtonTarget, this.dribbleButtonTarget,
      this.handoffButtonTarget, this.moveButtonTarget, this.passButtonTarget,
      this.pickButtonTarget, this.shotButtonTarget
    ]
    this.selectedButtons = [this.deleteButtonTarget, this.colorButtonTarget]
    disableButtons(this.selectedButtons)
    this.mode = MODE.IDLE
  }

  // --- Binding/Unbinding of events ---
  setupEventListeners() {
    this.bindWindowEvents()
    this.bindDiagramEvents()
  }

  bindWindowEvents() {
    this.handleResize = debounce(() => {
      this.scale = zoomToFit(this.diagramTarget, this.courtTarget, true)
    }, 250)

    window.addEventListener('resize', this.handleResize)
    window.addEventListener('keydown', this.onKeyDown.bind(this))
  }

  bindDiagramEvents() {
    this.diagramTarget.addEventListener('pointerdown', this.onPointerDown.bind(this))
    this.diagramTarget.addEventListener('pointerleave', this.onPointerLeave.bind(this))
    this.diagramTarget.addEventListener('pointermove', this.onPointerMove.bind(this))
    this.diagramTarget.addEventListener('pointerup', this.onPointerUp.bind(this))
    this.diagramTarget.addEventListener('dblclick', this.onDblClick.bind(this))
  }

  unbindWindowEvents() {
    window.removeEventListener('resize', this.handleResize)
    window.removeEventListener('keydown', this.onKeyDown)
  }

  unbindDiagramEvents() {
    this.diagramTarget.removeEventListener('dblclick', this.onDblClick)
    this.diagramTarget.removeEventListener('pointerdown', this.onPointerDown)
    this.diagramTarget.removeEventListener('pointerleave', this.onPointerLeave)
    this.diagramTarget.removeEventListener('pointermove', this.onPointerMove)
    this.diagramTarget.removeEventListener('pointerup', this.onPointerUp)
  }

  // --- Editor mode changes ---
  exitMode() {
    switch (this.mode) {
      case MODE.DRAG:
        this.stopDrag()
        break
      case MODE.DRAG_POINT:
        this.stopDragPoint()
        break
      case MODE.DRAW:
        this.cancelDrawing() // discard changes
        break
      case MODE.EDIT:
        this.stopEditingPath(true) // Cancel path editing
        break
      case MODE.PLACE:
        this.cancelPlacement()
        break
      case MODE.SELECT:
        this.clearSelection()
        this.hideColorMenu()
        break
      default:  //idle mode -- deselect selected object
        return
    }
  }

  // --- Event Management ---
  onDblClick(evt) {
    DEBUG === 'events' && console.log(`onDblClick(mode=${this.mode}]`)
    switch (this.mode) {
      case MODE.DRAW:
        this.stopDrawing()
        break
      case MODE.EDIT:
        this.stopEditingPath(false) // Finalize changes
        break
      case MODE.IDLE:
        this.handleSelection(evt)
      case MODE.SELECT:
        // Check if we're clicking on a path
        if ((this.selectedObject?.getAttribute('type') === 'path')) {
          this.startEditingPath(this.selectedObject)
        }
        return
    }
  }

  onKeyDown(evt) {
    DEBUG === 'events' && console.log(`onKeyDown(${evt.key}, mode=${this.mode}]`)
    switch (evt.key) {
      case 'Escape':
        this.exitMode()
        break
      case 'Delete':
        switch (this.mode) {
          case MODE.SELECT:
            this.deleteSelected()
            break
          case MODE.PLACE:
            this.cancelPlacement()
            break
        }
      default:
        return
    }
  }

  onPointerDown(evt) {
    DEBUG === 'events' && console.log(`onPointerDown(mode=${this.mode}]`)
    switch (this.mode) {
      case MODE.DRAW:
        this.addDrawingPoint(evt)
        break
      case MODE.EDIT:
        if (evt.target.classList.contains('control-point')) {
          this.startDragPoint(evt)
        }
        break
      case MODE.IDLE:
        this.handleSelection(evt)
      case MODE.SELECT:
        const wrapId = evt.target.closest('g.wrapper')?.getAttribute('id')
        const oSelId = this.selectedObject?.getAttribute('id')
        if (wrapId === oSelId) {
          this.startDrag(evt)
        } else {
          this.handleSelection(evt)
          if (this.selectedObject) { this.startDrag(evt) }
        }
        break
      case MODE.PLACE:
        this.stopSymbolPlacement(evt)
        break
      default:
        return
    }
  }

  onPointerUp(evt) {
    DEBUG === 'events' && console.log(`onPointerUp(mode=${this.mode}]`)
    switch (this.mode) {
      case MODE.DRAG:
        this.stopDrag(evt)   // Complete the object dragging
        break
      case MODE.DRAG_POINT:
        this.stopDragPoint(evt)  // Add this case
        break
      default:
        return
    }
  }

  onPointerLeave() {
    DEBUG === 'events' && console.log(`onPointerLeave(mode=${this.mode}]`)
    switch (this.mode) {
      case MODE.PLACE:
        this.cancelPlacement()
        break
      default:
        return
    }
  }

  onPointerMove(evt) {
    DEBUG === 'deep' && console.log(`onPointerMove(mode=${this.mode}]`)
    switch (this.mode) {
      case MODE.DRAW:
        this.trackDrawingPointer(evt)
        break
      case MODE.DRAG:
        this.dragObject(evt)  // Move a regular object
        break
      case MODE.DRAG_POINT:
        this.dragPoint(evt)  // Add this case
        break
      case MODE.PLACE:
        this.handlePlacementMove(evt)
        break
    }
  }

  // Dragging of symbols/points
  dragObject(evt) {
    if (!this.draggedObject) return

    const pt = getPointFromEvent(evt, this.diagramTarget)
    DEBUG === 'events' && console.log('dragObject([', pt.x, ', ', pt.y, '])')

    const { x: minX, y: minY, width, height } = this.courtBox
    const maxX = minX + width - 3 * SYMBOL_SIZE
    const maxY = minY + height - 3 * SYMBOL_SIZE
    // Bail out if outside allowed area (based on logical coords)
    if (pt.x < minX || pt.x > maxX || pt.y < minY || pt.y > maxY) {
      DEBUG && console.warn('Blocked drag outside court:', pt.x, pt.y)
      return
    }

    // Update logical position of the object nner <g>
    updatePosition(this.draggedObject, pt.x, pt.y)
    evt.preventDefault()
  }

  dragPoint(evt) {
    if (!this.draggedPoint) return
    const pt = getPointFromEvent(evt, this.diagramTarget)
    DEBUG && console.log('dragPoint(', this.draggedPoint, ' => ', pt, ')')

    // Update the point position
    this.tempPoints[this.draggedPointIndex] = pt

    // Update the visual point position
    this.draggedPoint.setAttribute('cx', pt.x)
    this.draggedPoint.setAttribute('cy', pt.y)

    // Update the path using the same method as when drawing
    updatePath(this.tempPath, this.tempPoints)

    evt.preventDefault()
  }

  startDrag(evt) {
    const wrapper = findNearbyObject(this.diagramTarget, evt)
    if (!wrapper) return

    this.draggedObject = wrapper
    this.draggedType = wrapper.getAttribute('type') || 'symbol'
    if (this.draggedType != 'symbol') return

    DEBUG && console.log(`startDrag(objecId: ${wrapper.getAttribute('id')})`)

    document.body.style.cursor = 'grabbing'
    evt.preventDefault()
    this.mode = MODE.DRAG
  }

  stopDrag() {
    document.body.style.cursor = ''
    if (this.draggedObject) {
      const x = this.draggedObject.dataset.x
      const y = this.draggedObject.dataset.y
      DEBUG && console.log('stopDrag:', this.draggedObject.id, 'coords:', x, y)
    }
    this.draggedObject = null
    this.mode = MODE.SELECT

  }

  startDragPoint(evt) {
    if (!this.tempPath) return
    const controlPoint = evt.target
    DEBUG && console.log('this.startDragPoint(controlPoint: ', controlPoint, ')')

    this.draggedPoint = controlPoint
    this.draggedPointIndex = parseInt(controlPoint.getAttribute('data-index'))
    controlPoint.style.cursor = 'grabbing'
    evt.preventDefault()
    this.mode = MODE.DRAG_POINT
  }

  stopDragPoint() {
    document.body.style.cursor = ''
    this.draggedPoint = null
    this.draggedPointIndex = -1
    this.mode = MODE.EDIT
  }

  // --- SVG symbol management ---
  addAttacker(evt) { this.addSymbol(evt, 'attacker', this.attackerNumbers) }
  addBall(evt) { this.addSymbol(evt, 'ball') }
  addCoach(evt) { this.addSymbol(evt, 'coach') }
  addCone(evt) { this.addSymbol(evt, 'cone', null, 0.07) }
  addDefender(evt) { this.addSymbol(evt, 'defender', this.defenderNumbers) }

  addSymbol(evt, kind, set = null) {
    const button = evt.currentTarget
    const svg = button.querySelector('svg[data-symbol-id]')
    const symbolId = svg?.dataset.symbolId
    if (!symbolId) {
      DEBUG && console.warn('button has no symbolId: ', button)
      return
    }

    // Enter symbol placement mode
    this.startSymbolPlacement(symbolId, kind, set)
  }

  startSymbolPlacement(symbolId, kind, set) {
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
    document.body.style.cursor = 'grabbing'
    this.placementSymbol.style.opacity = SYMBOL_PREVIEW_OPACITY
    this.placementSymbol.classList.add('placement-preview')

    // Add to diagram
    this.diagramTarget.appendChild(this.placementSymbol)

    // Set placement mode
    this.placementKind = kind
    this.placementSet = set
    this.mode = MODE.PLACE
  }

  handlePlacementMove(evt) {
    if (!this.placementSymbol) return

    // Update position with smooth transition
    const point = getPointFromEvent(evt, this.diagramTarget)
    this.placementSymbol.style.transition = 'transform 0.1s ease-out'
    updatePosition(this.placementSymbol, point.x, point.y)
  }

  stopSymbolPlacement(evt) {
    if (!this.placementSymbol) return

    const point = getPointFromEvent(evt, this.diagramTarget)

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

  cancelPlacement() {
    if (!this.placementSymbol) return

    this.placementSymbol.classList.add('fade-out')
    setTimeout(() => {
      if (this.placementSymbol && this.placementSymbol.parentNode) {
        this.deleteSymbolCounter(this.placementSymbol)
        this.placementSymbol.parentNode.removeChild(this.placementSymbol)
      }
      this.cleanupPlacementMode()
    }, 0)
  }

  cleanupPlacementMode() {
    document.body.style.cursor = ''
    this.placementSymbol = null
    this.placementKind = null
    this.placementSet = null
    this.mode = MODE.IDLE
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
  addDrawingPoint(evt) {
    if (this.mode !== MODE.DRAW) return
    this.drawingParams.scale = this.scale
    const point = getPointFromEvent(evt, this.diagramTarget)

    // Skip duplicate points (within 1px tolerance)
    if (this.tempPoints.length > 2) {
      const lastPoint = this.tempPoints[this.tempPoints.length - 1]
      const dx = point.x - lastPoint.x
      const dy = point.y - lastPoint.y
      const distanceSquared = dx * dx + dy * dy

      if (distanceSquared < 1) {  // 1px² tolerance
        DEBUG && console.log('Skipping duplicate point', point)
        return
      }
    }

    DEBUG && console.log('addDrawingPoint()', point,)
    this.tempPoints.push(point)

    // Update the path with the new fixed point
    if (!this.drawingParams.curve && this.tempPoints.length === 2) {
      this.stopDrawing()
    } else if (this.tempPoints.length >= 2) {
      updatePath(this.tempPath, this.tempPoints)
    }
  }

  cancelDrawing() {
    DEBUG && console.log('cancelDrawing()')
    this.currentPoint = null
    this.resetDrawingState()
    if (this.tempPath) {
      this.diagramTarget.removeChild(this.tempPath)
      this.tempPath = null
    }
    this.activeDrawingButton = null
  }

  resetDrawingState(mode = MODE.IDLE) {
    DEBUG && console.log(`resetDrawingState(${mode})`)
    lowlightButton(this.activeDrawingButton)
    this.tempPoints = []
    this.drawingParams = {}
    this.currentPoint = null
    this.mode = mode
  }

  startDrawing(evt) {
    const button = evt.currentTarget
    DEBUG && console.log('startDrawing ', button)

    if (this.mode === MODE.DRAW) {
      const end_drawing = (this.activeDrawingButton === button)
      this.cancelDrawing()
      if (end_drawing) return
    }

    this.resetDrawingState(MODE.DRAW)
    this.activeDrawingButton = button
    highlightButton(button)

    this.drawingParams = {
      curve: button.dataset.curve === 'true',
      style: button.dataset.style || 'solid',
      ending: button.dataset.ending || 'none',
      isPreview: true,
      scale: this.scale
    }
    DEBUG && console.log('drawingParams ', this.drawingParams)
    this.tempPath = createPath(this.tempPoints, this.drawingParams)
    this.diagramTarget.appendChild(this.tempPath)
  }

  stopDrawing() {
    DEBUG && console.log('stopDrawing()')
    if (this.mode !== MODE.DRAW) return
    if (this.tempPoints.length < 2 || (this.drawingParams.curve && this.tempPoints.length < MIN_POINTS_FOR_CURVE)) {
      return this.cancelDrawing()
    }

    this.drawingParams.isPreview = false
    this.drawingParams.color = this.activeDrawingButton.dataset.color || '#000000'  // re-set color
    updatePath(this.tempPath, this.tempPoints, this.drawingParams)
    this.resetDrawingState()
  }

  startEditingPath(pathWrapper) {
    DEBUG && console.log('startEditingPath()')
    this.clearSelection()
    disableButtons(this.allButtons)
    this.tempPath = pathWrapper
    // Store original attributes for potential cancellation
    this.originalPoints = this.tempPath.getAttribute('data-points')
    this.tempPoints = getPathPoints(this.tempPath)
    DEBUG && console.log('originalPoints: ', this.originalPoints)
    this.originalOptions = getPathOptions(this.tempPath)
    DEBUG && console.log('originalOptions: ', this.originalOptions)

    // Create and show control points using existing utility functions
    setPathEditMode(this.tempPath, true)
    this.mode = MODE.EDIT
  }

  stopEditingPath(cancel) {
    DEBUG && console.log(`stopEditingPath(cancel: ${cancel})`)
    if (this.mode !== MODE.EDIT) return

    if (cancel) { this.tempPath.setAttribute('data-points', this.originalPoints) }
    setPathEditMode(this.tempPath, false, this.originalOptions)

    // Reset state
    this.tempPath = null
    this.tempPoints = null
    this.originalOptions = null
    this.originalPoints = null
    enableButtons(this.idleButtons)
    this.mode = MODE.IDLE
  }

  trackDrawingPointer(evt) {
    if (this.mode !== MODE.DRAW || this.tempPoints.length === 0) return

    // Throttle with requestAnimationFrame
    if (this.trackAnimationFrame) cancelAnimationFrame(this.trackAnimationFrame)

    this.trackAnimationFrame = requestAnimationFrame(() => {
      this.currentPoint = getPointFromEvent(evt, this.diagramTarget)
      const tempPoints = [...this.tempPoints, this.currentPoint]
      updatePath(this.tempPath, tempPoints)
    })
  }

  // --- SVG object selection & removal ---
  clearSelection() {
    DEBUG && console.log('clearSelection: ', this.selectedObject)
    if (this.selectedObject) {
      lowlightElement(this.selectedObject)
      const indicator = this.selectedObject.querySelector('.selection-indicator')
      if (indicator) indicator.remove()
      this.selectedObject = null
      disableButtons(this.selectedButtons)
      this.mode = MODE.IDLE
    }
  }

  deleteSelected() {
    const wrapper = this.selectedObject
    if (!wrapper) return

    disableButtons(this.selectedButtons)
    this.deleteSymbolCounter(wrapper)
    wrapper.classList.add('opacity-0', 'transition-opacity', 'duration-300')
    setTimeout(() => {
      wrapper.remove()
      this.selectedObject = null
    }, 300)
    this.mode = MODE.IDLE
  }

  handleSelection(evt) {
    DEBUG && console.log(`handleSelection(mode==${this.mode})`)
    switch (this.mode) {
      case MODE.IDLE:
        this.selectObject(evt)
        break
      case MODE.SELECT:
        this.clearSelection()
        this.selectObject(evt)
      default:
        return
    }
  }

  selectObject(evt) {
    // Find nearby object
    let wrapper = findNearbyObject(this.diagramTarget, evt)
    if (wrapper) {
      this.selectedObject = wrapper
      highlightElement(wrapper)
      enableButtons(this.selectedButtons)

      if (DEBUG) {
        console.log('Selected:', {
          wrapper: wrapper.id,
          kind: wrapper.dataset.kind,
          number: getObjectNumber(wrapper)
        })
      }
      this.mode = MODE.SELECT
    }
  }

  // --- dynamic scaling ---
  zoomAfterRender() {
    requestAnimationFrame(() => {
      this.scale = zoomToFit(this.diagramTarget, this.courtTarget, true)
    })
  }

  // --- COLOR MANAGEMENT ---/
  applyColor(evt) {
    evt.preventDefault()
    evt.stopPropagation()

    const color = evt.currentTarget.dataset.color
    if (!this.selectedObject || !color) return

    // Apply color to the selected element
    if (this.selectedObject) {
      // Check if it's a path or symbol
      if (this.selectedObject.getAttribute('type') === 'path') {
        applyPathColor(this.selectedObject, color)
      } else {
        applySymbolColor(this.selectedObject, color)
      }
    }

    // Hide the menu after selection
    this.hideColorMenu()
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
    this.boundHideColorMenu = null // Clear reference
  }

  showColorMenu(evt) {
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

  // --- [END] SERIALIZE CONTENT ---/
  serialize() {
    try {
      const data = serializeDiagram(this.diagramTarget)
      this.svgdataTarget.value = JSON.stringify(data)
      DEBUG && console.log('Serialized data:', data)
    } catch (error) {
      console.error('Error serializing diagram:', error)
    }
  }
}