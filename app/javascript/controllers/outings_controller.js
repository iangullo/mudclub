// app/javascript/controllers/outings_controller.js
// Assistance from ChatGPT tweaking behaviour!
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["player"];

  connect() {
    // Get the table element
    const table = this.element;

    // Get the min, max, and firstPeriods values from data attributes
    this.min = parseInt(table.getAttribute("data-min"), 10);
    this.max = parseInt(table.getAttribute("data-max"), 10);
    this.totalPeriods = parseInt(table.getAttribute("data-tot"), 10);
    this.activePlayers = parseInt(table.getAttribute("data-act"), 10);
    this.firstPeriods = parseInt(table.getAttribute("data-first"), 10);

    // Wrap the asynchronous code inside an async function
    this.playerTargets.forEach((row) => {
      const checkbox = row.querySelector('input[type="checkbox"]');
      if (checkbox) {
        this.update({ target: checkbox }); // Manually call the update method
      }
    });
  }

  // Add an action to update the rule indicator based on the checkbox values
  update(event) {
    // Get the row element containing the changed checkbox
    const row = event.target.closest("tr");
    const rowId = event.target.dataset.rowid;
    const cues = [];

    // Get the checkboxes within the row
    const checkboxes = row.querySelectorAll("[data-target~='grid.checkbox'] input[type='checkbox']");

    // Perform your rule validation here by checking the checkboxes
    const isRuleMet = this.validateRule(checkboxes, rowId)

    // Update the rule indicator
    const ruleIndicator = row.querySelector("[data-target~='grid.ruleIndicator']")
    if (isRuleMet) {
      row.classList.remove("bg-red-300")
      ruleIndicator.innerHTML = ""

    } else {
      row.classList.add("bg-red-300")
      ruleIndicator.innerHTML = "<span class='text-red-700 font-black'>!!</span>"
    }
  }

  validateRule(checkboxes, rowId) {
    let checkedCount = 0

    // Iterate through checkboxes for the first 'n' periods
    for (let i = 1; i < (this.firstPeriods + 1); i++) {
      const checkboxId = `outings_${rowId}_q${i}`;
      const checkboxElement = document.getElementById(checkboxId);
      // Now access the checkbox element
      if (checkboxElement) {
        if (checkboxElement.checked) {
          checkedCount++;
        }
      } else {
        console.log(`${checkboxId} not found`);
      }
    }

    // Implement your rule validation logic here
    // Check checkedCount against this.min and this.max values
    return checkedCount >= this.min && checkedCount <= this.max
  }
}
