// app/javascript/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["trigger", "menu"]

    static values = {
        closeSiblings: { type: Boolean, default: true }
    }

    connect() {
        this.onClickOutside = this.onClickOutside.bind(this)
        this.onEscape = this.onEscape.bind(this)

        // Listeners are registered once and gated by isOpen — no setTimeout,
        // no re-registration races, no state drift.
        document.addEventListener("click", this.onClickOutside)
        document.addEventListener("keydown", this.onEscape)
    }

    disconnect() {
        document.removeEventListener("click", this.onClickOutside)
        document.removeEventListener("keydown", this.onEscape)
    }

    // Derived from the DOM, not from an instance variable.
    // Whatever writes aria-expanded is the single source of truth.
    get isOpen() {
        return this.triggerTarget.getAttribute("aria-expanded") === "true"
    }

    toggle(event) {
        event?.preventDefault()
        if (this.isOpen) {
            this.close()
        } else {
            if (this.closeSiblingsValue) this.closeSiblings()
            this.open()
        }
    }

    open() {
        this.menuTarget.classList.remove("hidden")
        this.triggerTarget.setAttribute("aria-expanded", "true")
    }

    close() {
        this.menuTarget.classList.add("hidden")
        this.triggerTarget.setAttribute("aria-expanded", "false")
        this.closeDescendants()
    }

    // Closes any nested dropdowns so their isOpen state can't drift.
    closeDescendants() {
        this.element.querySelectorAll("[data-controller~='dropdown']").forEach((el) => {
            const ctrl = this.application.getControllerForElementAndIdentifier(el, "dropdown")
            ctrl?.close()
        })
    }

    // Closes sibling dropdowns (not ancestors, not descendants) on open.
    closeSiblings() {
        document.querySelectorAll("[data-controller~='dropdown']").forEach((el) => {
            if (el === this.element) return
            if (this.element.contains(el)) return   // descendant — leave alone
            if (el.contains(this.element)) return   // ancestor — leave alone
            const ctrl = this.application.getControllerForElementAndIdentifier(el, "dropdown")
            ctrl?.close()
        })
    }

    onClickOutside(event) {
        if (!this.isOpen) return
        if (!this.element.contains(event.target)) this.close()
    }

    onEscape(event) {
        if (!this.isOpen) return
        if (event.key === "Escape") {
            this.close()
            this.triggerTarget.focus()
        }
    }
}