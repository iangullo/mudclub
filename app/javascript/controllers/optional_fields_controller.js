// app/javascript/controllers/optional_fields_controller.js
import { Controller } from "@hotwired/stimulus"

const RULES = {
    // Checkbox: checked → show the section
    checkbox: el => el.checked,

    // For person forms detecting underage people → show the guardian section
    underage: el => {
        if (!el.value) return false
        const birth = new Date(el.value)
        if (isNaN(birth)) return false

        const now = new Date()
        let age = now.getFullYear() - birth.getFullYear()
        const monthDiff = now.getMonth() - birth.getMonth()
        if (monthDiff < 0 || (monthDiff === 0 && now.getDate() < birth.getDate())) {
            age--
        }
        return age < 18
    }
}

export default class extends Controller {
    static targets = ["switch", "section"]

    connect() {
        this.switchTargets.forEach(s => this.updateSection(s))
    }

    toggle(event) {
        this.updateSection(event.target)
    }

    updateSection(trigger) {
        const name = trigger.dataset.optionalTarget
        const sections = this.sectionTargets.filter(
            s => s.dataset.optionalName === name
        )
        if (sections.length === 0) return

        const ruleName = trigger.dataset.optionalRule || "checkbox"
        const rule = RULES[ruleName]
        if (!rule) {
            console.warn(`[optional-fields] unknown rule: ${ruleName}`)
            return
        }

        const visible = rule(trigger)

        sections.forEach(section => {
            section.classList.toggle("hidden", !visible)
            section
                .querySelectorAll("input, select, textarea")
                .forEach(el => el.disabled = !visible)
        })

        this.dispatch("changed")
    }
}