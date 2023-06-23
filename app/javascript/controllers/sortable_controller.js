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
    console.log('before removing element');

    const item = event.currentTarget.closest(".draggable");
    const destroyInput = item.querySelector("[name*='_destroy']");
    const idInput = item.querySelector("input[name*='[id]']").value;

    if (destroyInput) {
      console.log('removing an item with ID:', idInput)
      destroyInput.value = "1";
    } else {
      console.log('prearing item to remove with ID:', idInput)
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

  get preventDefault() {
    return this.data.get("preventDefault") === "true";
  }

  onSubmit(event) {
    // If the submit event originates from a descendant element of the sortable list,
    // prevent the form submission
    if (event.target.closest(".draggable")) {
      event.preventDefault();
    }
  }
}
