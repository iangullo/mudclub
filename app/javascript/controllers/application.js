import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

// Import and register stimulus-rails-nested-form
import NestedForm from "stimulus-rails-nested-form"
application.register("nested-form", NestedForm)

// Import and register all TailwindCSS Components
import { Alert, Dropdown, Modal } from "tailwindcss-stimulus-components"
application.register('alert', Alert)
application.register('dropdown', Dropdown)
application.register('modal', Modal)

export { application }
