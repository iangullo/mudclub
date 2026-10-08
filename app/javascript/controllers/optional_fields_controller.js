// controllers/optional_fields_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["switch", "section"]

    connect() {
        this.switchTargets.forEach(s => this.updateSection(s))
    }

    toggle(event) {
        this.updateSection(event.target)
    }

    updateSection(checkbox) {
        const target = checkbox.dataset.optionalTarget

        const section = this.sectionTargets.find(
            s => s.dataset.optionalName === target
        )

        if (!section) return

        const visible = checkbox.checked
        console.log("  () updateSection.visible: ", visible)

        section.classList.toggle("hidden", !visible)

        section
            .querySelectorAll("input, select, textarea")
            .forEach(el => el.disabled = !visible)
    }
}