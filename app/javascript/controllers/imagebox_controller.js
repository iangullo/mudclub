// app/javascript/controllers/imagebox_controller.js
// Assistance from ChatGPT tweaking behaviour
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['selectedImage', 'imageFile'];

  openFileDialog() {
    // Trigger the click event on the hidden file input
    this.imageFileTarget.click()
  }

  handleFileChange(event) {
    const fileInput = event.target;
    const selectedImage = this.selectedImageTarget;

    // Check if a file was selected
    if (fileInput.files.length > 0) {
      const file = fileInput.files[0]

      // Display the selected image
      this.displayImage(file, selectedImage)
    }
  }

  displayImage(file, imageElement) {
    const reader = new FileReader()

    reader.onload = (event) => {
      const imageUrl = event.target.result
      imageElement.src = imageUrl
    };

    reader.readAsDataURL(file)
  }
}
