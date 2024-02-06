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
  }

  submit(event) {
    const button = event.currentTarget;
    const requiresConfirmation = button.dataset.confirm; // Check if button requires confirmation

    if (requiresConfirmation !== null) {
        if (confirm(requiresConfirmation)) {
            this.showProcessingCue();
        }
    } else {
        this.showProcessingCue();
    }
  }

  hideProcessingCue() {
    this.processingCueTarget.classList.add("hidden"); // unhide loading cue
  }

  showProcessingCue() {
    this.processingCueTarget.classList.remove("hidden"); // unhide loading cue
  }
}
