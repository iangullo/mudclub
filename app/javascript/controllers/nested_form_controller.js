// app/javascript/controllers/nested_form_controller.js
// Manages dynamic update of nested forms.
// Assistance from DeepSeek tweaking behaviour!
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "template", "item"]
 
  add(event) {
    if (!this.templateTarget.innerHTML) {
      console.error("Template is empty!")
    }
    event.preventDefault()
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())
    this.containerTarget.insertAdjacentHTML('beforeend', content)
  }

  remove(event) {
    event.preventDefault()
    const item = event.target.closest("[data-nested-form-target='item']")
    
    if (item) {
      const destroyInput = item.querySelector("input[name*='_destroy']")
      
      if (destroyInput) {
        // Mark existing record for destruction
        destroyInput.value = "1"
        item.classList.add("hidden")
      } else {
        // Remove new record
        item.remove()
      }
    }
  }
}