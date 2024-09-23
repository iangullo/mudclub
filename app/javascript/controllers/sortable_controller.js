// app/javascript/controllers/sortable_controller.js
//
// adapting from: https://www.stimulus-components.com/docs/stimulus-sortable/
// Assistance from ChatGPT4 tweaking behaviour!
import { Controller } from "@hotwired/stimulus"
import Sortable from 'stimulus-sortable'

export default class extends Sortable {
  static targets = [ "sortable-list" ]

  connect() {
    super.connect();
    this.isDragging = false;
    this.startX = 0;
    this.startY = 0;  
  }

  startDrag(event) {
    this.startX = event.clientX || event.touches[0].clientX;
    this.startY = event.clientY || event.touches[0].clientY;
    this.isDragging = false;
  }
  
  moveDrag(event) {
    const currentX = event.clientX || event.touches[0].clientX;
    const currentY = event.clientY || event.touches[0].clientY;
    
    // If the movement is significant, it's a drag, not a click
    if (Math.abs(currentX - this.startX) > 5 || Math.abs(currentY - this.startY) > 5) {
      this.isDragging = true;
    }
  }

  endDrag(event) {
    if (!this.isDragging) {
      event.preventDefault(); // It's a click, not a drag
      this.handleClick(event);
    }
  }

  handleClick(event) {
    const button = event.target.closest("button");
    if (button) {
      button.click();
    }
  }

  remove(event) {
    const item = event.currentTarget.closest(".draggable");
    const destroyInput = item.querySelector("[name*='_destroy']");
    const idInput = item.querySelector("input[name*='[id]']").value;

    if (destroyInput) {
      destroyInput.value = "1";
    } else {
      const hiddenInput = document.createElement("input");
      hiddenInput.type = "hidden";
      hiddenInput.name = item.querySelector("[name*='[id]']").name.replace("[id]", "[_destroy']");
      hiddenInput.value = "1";
      item.appendChild(hiddenInput);
    }

    //console.log('hiding item with ID:', idInput)
    item.style.display = "none";

    event.preventDefault();
  }

  onSubmit(event) {
    // If the submit event originates from a descendant element of the sortable list,
    // prevent the form submission
    if (event.target.closest(".draggable")) {
      event.preventDefault();
    }
  }
}
