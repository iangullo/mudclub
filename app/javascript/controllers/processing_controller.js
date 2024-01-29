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

  submit() {
    this.showProcessingCue();
  }

  hideProcessingCue() {
    this.processingCueTarget.classList.add("hidden"); // unhide loading cue
  }

  showProcessingCue() {
    this.processingCueTarget.classList.remove("hidden"); // unhide loading cue
  }
}
