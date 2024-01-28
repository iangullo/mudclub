// app/javascript/controllers/outings_controller.js
// Assistance from ChatGPT tweaking behaviour!
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["player"];

  connect() {
    // Get the table element
    const table = this.element;

    // Get the min, max, and firstPeriods values from data attributes
    this.rows = table.querySelectorAll("tr");
    this.min = parseInt(table.getAttribute("data-min"), 10);
    this.max = parseInt(table.getAttribute("data-max"), 10);
    this.totalPeriods = parseInt(table.getAttribute("data-tot"), 10);
    this.activePlayers = parseInt(table.getAttribute("data-act"), 10);
    this.firstPeriods = parseInt(table.getAttribute("data-first"), 10);
    this.checkboxes = {};

    // Iterate through rows to dynamically discover column IDs and store checkboxes
    this.playerTargets.forEach((row) => {
      const checkboxesInRow = row.querySelectorAll("input[type='checkbox']");
      checkboxesInRow.forEach((checkbox) => {
        const columnId = checkbox.getAttribute("data-columnId");
        if (!this.checkboxes[columnId]) {
          this.checkboxes[columnId] = [];
        }
        this.checkboxes[columnId].push(checkbox);
        this.update({ target: checkbox }); // Manually call the update method
      });
    });
  }

  // Add an action to update the rule indicator based on the checkbox values
  update(event) {
    // Get the row & col element containing the changed checkbox
    const row = event.target.closest("tr");
    const rowId = event.target.dataset.rowid;
    const columnId = event.target.dataset.columnid;

    // Perform your rule validation here by checking the checkboxes for row & column
    const isRowRuleMet = this.validateRow(rowId);
    const isColRuleMet = this.validateColumn(columnId);
    this.updateRowIndicator(row, isRowRuleMet);
    this.updateColIndicator(columnId, isColRuleMet);
  }

  validateRow(rowId) {
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
      }
    }
    //console.log(`validateRow(${rowId}) ==> ${checkedCount}`)
    // Implement your rule validation logic here
    // Check checkedCount against this.min and this.max values
    return checkedCount >= this.min && checkedCount <= this.max
  }

  // Update the Row indicator
  updateRowIndicator(row, isRowRuleMet) {
    if (isRowRuleMet) {  // provide cue that Rule is NOT met
      row.classList.remove("bg-red-300");
    } else {  // erase cue
      row.classList.add("bg-red-300");
    }
  }

  getColumn(columnId) {
    const column = [];

    this.checkboxes[columnId].forEach((checkbox) => {
      column.push(checkbox);
    });

    return column;
  }

  validateColumn(columnId) {
    let columnOutings = 0;
    const column = this.getColumn(columnId)

    // Iterate through column to collect the checked checkboxes
    column.forEach((checkbox) => {
      if (checkbox.checked) {
        columnOutings++;
      }
    });

    //console.log(`validateColumn(${columnId}) ==> ${columnOutings}`)
    return columnOutings === this.activePlayers;
  }

  updateColIndicator(columnId, isColRuleMet) {
    const colCells = document.querySelectorAll(`[data-columnId='${columnId}']`)
    if (isColRuleMet) {  // erase cue
      colCells.forEach((cell) => {
        cell.classList.remove("bg-red-300");
      });
    } else {  // provide cue that Rule is NOT met
      colCells.forEach((cell) => {
        cell.classList.add("bg-red-300");
      });
    }

  }
}
