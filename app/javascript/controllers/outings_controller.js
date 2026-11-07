// app/javascript/controllers/outings_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["athlete"]

  connect() {
    // Get the table element
    const table = this.element

    // Get the min, max, and firstPeriods values from data attributes
    this.rows = table.querySelectorAll("tr")
    this.min = parseInt(table.getAttribute("data-min"), 10)
    this.max = parseInt(table.getAttribute("data-max"), 10)
    this.totalPeriods = parseInt(table.getAttribute("data-tot"), 10)
    this.activeAthletes = parseInt(table.getAttribute("data-act"), 10)
    this.firstPeriods = parseInt(table.getAttribute("data-first"), 10)
    this.checkboxes = {}

    // Iterate through rows to dynamically discover column IDs and store checkboxes
    this.athleteTargets.forEach((row) => {
      row.querySelectorAll("input[type='checkbox']").forEach((checkbox) => {
        const columnId = checkbox.dataset.columnId;
        (this.checkboxes[columnId] ||= []).push(checkbox)
      })
    })

    // Single pass for initial validation of all checkboxes
    Object.keys(this.checkboxes).forEach((columnId) => {
      this.updateColIndicator(columnId, this.validateColumn(columnId))
    })
    this.athleteTargets.forEach((row) => {
      const rowId = row.querySelector("input[type='checkbox']")?.dataset.rowId
      if (rowId) this.updateRowIndicator(row, this.validateRow(rowId))
    })
  }

  // Add an action to update the rule indicator based on the checkbox values
  update(event) {
    // Get the row & col element containing the changed checkbox
    const row = event.target.closest("tr")
    const rowId = event.target.dataset.rowId
    const columnId = event.target.dataset.columnId
    console.log(`updated(rowId: ${rowId}, colId: ${columnId})`)

    // Perform your rule validation here by checking the checkboxes for row & column
    const isRowRuleMet = this.validateRow(rowId)
    const isColRuleMet = this.validateColumn(columnId)
    this.updateRowIndicator(row, isRowRuleMet)
    this.updateColIndicator(columnId, isColRuleMet)
  }

  validateRow(rowId) {
    let checkedCount = 0

    // Iterate through checkboxes for the first 'n' periods
    for (let i = 1; i < (this.firstPeriods + 1); i++) {
      const checkboxId = `outings_${rowId}_q${i}`
      const checkboxElement = document.getElementById(checkboxId)
      // Now access the checkbox element
      if (checkboxElement) {
        if (checkboxElement.checked) {
          checkedCount++
        }
      }
    }
    console.log(`validateRow(${rowId}) ==> ${checkedCount}`)
    // Check checkedCount against this.min and this.max values
    return checkedCount >= this.min && checkedCount <= this.max
  }

  // Update the Row indicator
  updateRowIndicator(row, isRowRuleMet) {
    if (isRowRuleMet) {  // provide cue that Rule is NOT met
      row.classList.remove("bg-red-300")
    } else {  // erase cue
      row.classList.add("bg-red-300")
    }
  }

  getColumn(columnId) {
    const column = []

    this.checkboxes[columnId].forEach((checkbox) => {
      column.push(checkbox)
    })

    return column
  }

  validateColumn(columnId) {
    let columnOutings = 0
    const column = this.getColumn(columnId)

    // Iterate through column to collect the checked checkboxes
    column.forEach((checkbox) => {
      if (checkbox.checked) {
        columnOutings++
      }
    })

    console.log(`validateColumn(${columnId}) ==> ${columnOutings}`)
    return columnOutings === this.activeAthletes
  }

  updateColIndicator(columnId, isColRuleMet) {
    const checkboxes = document.querySelectorAll(`input[data-column-id='${columnId}']`)
    checkboxes.forEach((cb) => {
      const cell = cb.closest("td")
      if (cell) {
        cell.classList.toggle("bg-red-300", !isColRuleMet)
      }
    })

  }
}
