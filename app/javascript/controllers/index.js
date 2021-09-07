import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "@hotwired/stimulus"
//import { definitionsFromContext } from "stimulus/webpack-helpers"

const application = Application.start()
const context = require.context("controllers", true, /_controller\.(js|ts)$/)
application.load(definitionsFromContext(context))

// Configure Stimulus development experience
application.warnings = true
application.debug    = false
window.Stimulus      = application

// Import and register all TailwindCSS Components
import { Alert, Autosave, Dropdown, Modal, Tabs, Popover, Toggle, Slideover } from "tailwindcss-stimulus-components"
application.register('alert', Alert)
application.register('autosave', Autosave)
application.register('dropdown', Dropdown)
application.register('modal', Modal)
application.register('tabs', Tabs)
application.register('popover', Popover)
application.register('toggle', Toggle)
application.register('slideover', Slideover)

// Import and register all your controllers within this directory and all subdirectories
// Controller files must be named *_controller.js or *_controller.ts
