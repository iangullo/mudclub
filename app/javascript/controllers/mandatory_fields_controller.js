// app/javascript/controllers/mandatory_fields_controller.js
//
// Manage mandatory fields in forms and toggle submit buttons accordingly.

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    //console.log('Connecting mandatory-fields controller...');
    // Find the submit button within the form
    this.submitButton = this.element.querySelector('button[type="submit"]');
    
    // Find the hover div (assumed to be within the form element)
    this.hoverDiv = this.element.querySelector(".hover-div");

    
    // Get all mandatory fields
    this.mandatoryFields = Array.from(this.element.querySelectorAll('[data-mandatory-input="true"]'));

    // Initial overall validity state
    this.allValid = true;
    
    // Add input event listeners to all mandatory fields
    this.mandatoryFields.forEach(field => {
      field.addEventListener('input', () => this.checkField(field));
      //console.log('Mandatory field: ', field);
      
      // Initial validation of each field
      if (!this.validateField(field)) {
        this.allValid = false;
      }
    });

    // Initial check of all fields to set the submit button state correctly
    this.toggleButtonState(this.allValid);
  }

  checkField(field) {
    // Validate the individual field
    const isValid = this.validateField(field);
    
    // Update the overall validity state based on the changed field
    if (isValid) {
      this.allValid = this.mandatoryFields.every(f => this.validateField(f));
    } else {
      this.allValid = false;
    }

    // Update the submit button state
    //console.log('Submit button disabled state before update:', this.submitButton.disabled);
    this.toggleButtonState(this.allValid);
    //console.log('Submit button disabled state after update:', this.submitButton.disabled);
  }

  validateField(field) {
    const [rule, value] = field.dataset.condition.split(":");
    //console.log('Validating mandatory field (', field, ')');

    // Perform validation based on the rule
    let isValid = this[rule](field.value, value);

    // Update field styles based on validation result
    if (isValid) {
      field.classList.add("border-gray-200", "focus:ring-blue-700");
      field.classList.remove("border-red-500", "focus:ring-red-500");
    } else {
      field.classList.add("border-red-500", "focus:ring-red-500");
      field.classList.remove("border-gray-200", "focus:ring-blue-700");
    }
    return isValid;
  }

  length(value, expectedLength) {
    return value.length >= expectedLength;
  }

  min(value, minValue) {
    return parseInt(value) >= parseInt(minValue);
  }

  max(value, maxValue) {
    return parseInt(value) <= parseInt(maxValue);
  }

  toggleButtonState(isEnabled) {
    // Enable or disable the submit button based on validation
    this.submitButton.disabled = !isEnabled;

    // Update button and hover div styles based on validation
    if (isEnabled) {
      this.submitButton.classList.remove("text-gray-500", "cursor-not-allowed", "opacity-50");
      if (this.hoverDiv) {
        this.hoverDiv.classList.add("hover:bg-green-200");
      }
    } else {
      this.submitButton.classList.add("text-gray-500", "cursor-not-allowed", "opacity-50");
      if (this.hoverDiv) {
        this.hoverDiv.classList.remove("hover:bg-green-200");
      }
    }
  }
}
