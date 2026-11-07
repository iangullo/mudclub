// app/javascript/controllers/mandatory_fields_controller.js
//
// Manage mandatory fields in forms and toggle submit buttons accordingly.

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    //console.log('Connecting mandatory-fields controller...')
    // Find the submit button within the form
    this.submitButton = this.element.querySelector('button[type="submit"]')

    // Find the hover div (assumed to be within the form element)
    this.hoverDiv = this.element.querySelector(".hover-div")


    // Get all mandatory fields
    this.mandatoryFields = Array.from(this.element.querySelectorAll('[data-mandatory-input="true"]'))

    // Initial overall validity state
    this.allValid = true

    // Add input event listeners to all mandatory fields
    this.mandatoryFields.forEach(field => {
      //console.log('Mandatory field: ', field)
      field.addEventListener('input', () => this.checkField(field))
      field.addEventListener('change', () => this.checkField(field))

      // Initial validation of each field
      if (!this.validateField(field)) {
        this.allValid = false
      }
    })

    // Initial check of all fields to set the submit button state correctly
    this.toggleButtonState(this.allValid)
  }

  checkField(field) {
    // Validate the individual field
    const isValid = this.validateField(field)

    // Update the overall validity state based on the changed field
    this.allValid = isValid
      ? this.mandatoryFields.every(f => this.validateField(f))
      : false

    // Update the submit button state
    this.toggleButtonState(this.allValid)
    //console.log('Submit button disabled state after update:', this.submitButton.disabled)
  }

  refresh() {
    this.allValid = this.mandatoryFields.every(field => this.validateField(field))
    this.toggleButtonState(this.allValid)
  }

  validateField(field) {
    if (field.disabled) {
      field.classList.remove("border-red-500", "border-2", "focus:ring-red-500")
      field.classList.add("border-gray-200", "focus:ring-blue-700")
      return true
    }

    if (this.mandatoryWaived(field)) {
      field.classList.remove("border-red-500", "border-2", "focus:ring-red-500")
      field.classList.add("border-gray-200", "focus:ring-blue-700")
      return true
    }

    const raw = field.dataset.condition || ""
    const parts = raw.split(";").filter(Boolean)

    //console.log('Validating mandatory field (', field, ')')

    // Perform validation based on the rule
    let isValid = true

    for (const part of parts) {
      const [rule, value] = part.split(":")
      const fn = this[rule]
      if (!fn) continue
      if (!fn.call(this, field.value, value)) { isValid = false; break }
    }

    // Update field styles based on validation result
    if (isValid) {
      field.classList.add("border-gray-200", "focus:ring-blue-700")
      field.classList.remove("border-red-500", "border-2", "focus:ring-red-500")
    } else {
      field.classList.add("border-red-500", "border-2", "focus:ring-red-500")
      field.classList.remove("border-gray-200", "focus:ring-blue-700")
    }

    return isValid
  }

  mandatoryWaived(field) {
    const selector = field.dataset.mandatoryUnless
    if (!selector) return false
    return !!this.element.querySelector(selector)
  }

  length(value, expectedLength) {
    return value.length >= expectedLength
  }

  min(value, minValue) {
    return parseInt(value) >= parseInt(minValue)
  }

  max(value, maxValue) {
    return parseInt(value) <= parseInt(maxValue)
  }

  presence(value, _) {
    return value != null && value.toString().trim() !== ""
  }

  date_min(value, minValue) {
    if (!value) return false
    return value >= minValue          // ISO YYYY-MM-DD compares lexicographically
  }

  date_max(value, maxValue) {
    if (!value) return false
    return value <= maxValue
  }

  toggleButtonState(isEnabled) {
    if (!this.submitButton) return

    // Enable or disable the submit button based on validation
    this.submitButton.disabled = !isEnabled

    // Update button and hover div styles based on validation
    if (isEnabled) {
      this.submitButton.classList.remove("text-gray-500", "cursor-not-allowed", "opacity-50")
      if (this.hoverDiv) {
        this.hoverDiv.classList.add("hover:bg-green-200")
      }
    } else {
      this.submitButton.classList.add("text-gray-500", "cursor-not-allowed", "opacity-50")
      if (this.hoverDiv) {
        this.hoverDiv.classList.remove("hover:bg-green-200")
      }
    }
  }
}
