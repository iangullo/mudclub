// app/javascript/controllers/sortable_controller.js
//
// adapting from: https://www.stimulus-components.com/docs/stimulus-sortable/
// Assistance from ChatGPT4 tweaking behaviour!
import { Controller } from "@hotwired/stimulus"
import Sortable from 'stimulus-sortable'

export default class extends Sortable {
  static targets = [ "sortable-list" ]

  connect() {
    super.connect()
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

    console.log('hiding item with ID:', idInput)
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
