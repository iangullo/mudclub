// app/stimulus/controllers/diagram_renderer_controller.js
// Developed with significant help from DeepSeek
import { Controller } from "@hotwired/stimulus"
import { loadDiagramContent, zoomToFit } from "helpers/svg_loader"

export default class extends Controller {
  static targets = ["diagram", "court"]
  static values = { svgdata: String }

  connect() {
    if (this.hasSvgdataValue) {
      // Load diagram without editor-specific logic
      loadDiagramContent(this.diagramTarget, this.svgdataValue)
    }

    this.zoomAfterRender()
    this.setupEventListeners()
  }

  setupEventListeners() {
    this.handleResize = () => {
      this.scale = zoomToFit(this.diagramTarget, this.courtTarget)
    }

    window.addEventListener('resize', this.handleResize)
  }

  disconnect() {
    window.removeEventListener('resize', this.handleResize)
  }

  zoomAfterRender() {
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        const scale = zoomToFit(this.diagramTarget, this.courtTarget)
        
        // Additional centering logic
        const container = this.diagramTarget.closest('.step-diagram')
        if (container) {
          const svgWidth = this.diagramTarget.clientWidth
          const containerWidth = container.clientWidth
          
          if (svgWidth < containerWidth) {
            this.diagramTarget.style.marginLeft = `${(containerWidth - svgWidth) / 2}px`
          }
        }
      })
    })
  }
}