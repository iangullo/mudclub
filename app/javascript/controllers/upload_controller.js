// app/javascript/controllers/upload_controller.js
// Assistance from ChatGPT tweaking behaviour
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fileInput", "fileName", "button"];

  selectFile() {
    const fileInput = this.fileInputTarget;
    if (fileInput) {
      fileInput.click(); // Trigger the hidden file input
      fileInput.addEventListener("change", () => {
        const fileNameDisplay = this.fileNameTarget;
        if (fileNameDisplay) {
          const selectedFiles = fileInput.files;
          if (selectedFiles.length > 0) {
            fileNameDisplay.textContent = selectedFiles[0].name; // Display selected file name
          }
        }
      });
    }
  }
}
