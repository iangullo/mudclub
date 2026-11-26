// app/javascript/controllers/processing_controller.js
// Manages toggling visual cues to let the user know that a request is
// being processed.
// Assistance from ChatGPT tweaking behaviour!
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["processingCue"];

  connect() {
    if (this.hasProcessingCueTarget && this.data.get("processing")) {
      this.showProcessingCue();
    }

    this.form = this.element.closest("form");
    if (this.form) {
      // Turbo reads data-turbo-confirm from <form>, not <button type="submit">
      const btnWithConfirm = this.element.querySelector("[data-turbo-confirm]");
      if (btnWithConfirm) {
        if (!this.form.dataset.turboConfirm) {
          this.form.dataset.turboConfirm = btnWithConfirm.dataset.turboConfirm;
        }
        delete btnWithConfirm.dataset.turboConfirm;
      }

      this.startHandler = () => this.showProcessingCue();
      this.endHandler = () => this.hideProcessingCue();
      this.form.addEventListener("turbo:submit-start", this.startHandler);
      this.form.addEventListener("turbo:submit-end", this.endHandler);
    }
  }

  disconnect() {
    if (this.form) {
      this.form.removeEventListener("turbo:submit-start", this.startHandler);
      this.form.removeEventListener("turbo:submit-end", this.endHandler);
    }
  }

  // Keep for non-form buttons (e.g., links or custom actions with working: true)
  submit() {
    if (!this.form) {
      this.showProcessingCue();
    }
  }

  hideProcessingCue() {
    if (this.hasProcessingCueTarget) {
      this.processingCueTarget.classList.add("hidden");
    }
  }

  showProcessingCue() {
    if (this.hasProcessingCueTarget) {
      this.processingCueTarget.classList.remove("hidden");
    }
  }
}
