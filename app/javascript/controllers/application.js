import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

// Import and register stimulus-rails-nested-form
import NestedForm from "stimulus-rails-nested-form"
application.register("nested-form", NestedForm)
export { application }
