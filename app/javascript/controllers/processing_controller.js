// app/javascript/controllers/processing_controller.js
// Manages toggling visual cues to let the user know that a request is
// being processed.
// Assistance from ChatGPT tweaking behaviour!
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["processingCue"];
  originalButton = null;

  connect() {
    this.originalButton = this.element.querySelector("[data-action='processing#submit']");
    if (this.hasProcessingCueTarget && this.data.get("processing")) {
      this.showProcessingCue();
    }
  }

  submit() {
    this.disableButton();
  }

  disableButton() {
    this.originalButton.setAttribute("disabled", true);
    this.originalButton.classList.add("bg-gray-100"); // Add your CSS class for showing the loading cue
    this.showProcessingCue();
  }

  enableButton() {
    this.originalButton.removeAttribute("disabled");
    this.originalButton.classList.remove("bg-gray-100"); // Add your CSS class for showing the loading cue
    this.hideProcessingCue();
  }
  
  hideProcessingCue() {
    this.processingCueTarget.classList.add("hidden"); // unhide loading cue
  }

  showProcessingCue() {
    this.processingCueTarget.classList.remove("hidden"); // unhide loading cue
  }
}
