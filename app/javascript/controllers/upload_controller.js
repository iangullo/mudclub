// app/javascript/controllers/upload_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fileInput", "fileName"]

  selectFile(event) {
    event.preventDefault()
    this.fileInputTarget.click()
  }

  displayName() {
    const files = this.fileInputTarget.files
    this.fileNameTarget.textContent = files.length ? files[0].name : ""
  }
}
