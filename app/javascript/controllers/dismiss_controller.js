// app/javascript/controllers/dismiss_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        autoDismiss: { type: Boolean, default: false },
        delay: { type: Number, default: 5000 }
    }

    connect() {
        if (this.autoDismissValue) {
            this.timer = setTimeout(() => this.dismiss(), this.delayValue)
        }
    }

    disconnect() {
        clearTimeout(this.timer)
    }

    dismiss(event) {
        event?.preventDefault()
        clearTimeout(this.timer)
        this.element.style.transition = "opacity 150ms ease"
        this.element.style.opacity = "0"
        setTimeout(() => this.element.remove(), 150)
    }
}