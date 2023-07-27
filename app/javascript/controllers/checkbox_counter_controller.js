// app/javascript/controllers/checkbox_counter_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["checkbox", "rowCounter", "totalCounter"];

  connect() {
    this.updateCounters();
  }

  updateCounters() {
    let totalChecked = 0;

    this.checkboxTargets.forEach((checkbox) => {
      if (checkbox.checked || checkbox.value === "1") {
        totalChecked++;
      }
    });

    this.rowCounterTargets.forEach((counter) => {
      const rowId = counter.getAttribute("data-row-id");
      const q = counter.getAttribute("data-q");
      const rowCheckboxes = this.checkboxTargets.filter(
        (checkbox) =>
          checkbox.getAttribute("data-row-id") === rowId &&
          checkbox.getAttribute("data-q") === q
      );
      let selectedInRow = rowCheckboxes.filter(
        (checkbox) => checkbox.checked || checkbox.value === "1"
      ).length;
      counter.textContent = selectedInRow.toString();
    });

    this.totalCounterTarget.textContent = totalChecked.toString();
  }

  checkboxChanged(event) {
    this.updateCounters();
  }
}
