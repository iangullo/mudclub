// app/javascript/controllers/accordion_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    toggle(event) {
        const button = event.currentTarget
        const selector = button.dataset.accordionTarget
        const body = this.element.querySelector(selector)
        if (!body) return

        const wasOpen = button.getAttribute("aria-expanded") === "true"

        // --- modo exclusivo (equivalente a Flowbite data-accordion="collapse") ---
        // cierra cualquier otro item abierto del mismo acordeón
        /* this.element
            .querySelectorAll('[data-accordion-target][aria-expanded="true"]')
            .forEach((other) => {
                if (other === button) return
                other.setAttribute("aria-expanded", "false")
                const otherBody = this.element.querySelector(other.dataset.accordionTarget)
                otherBody?.classList.add("hidden")
                other.querySelector("[data-accordion-icon]")?.classList.add("rotate-180")
            })
        */
        // --- toggle del item pulsado ---
        button.setAttribute("aria-expanded", String(!wasOpen))
        body.classList.toggle("hidden", wasOpen)
        button.querySelector("[data-accordion-icon]")?.classList.toggle("rotate-180", wasOpen)
    }
}