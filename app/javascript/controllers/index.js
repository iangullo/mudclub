// Load all the controllers within this directory and all subdirectories.
// Controller files must be named *_controller.js.

import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"

const application = Application.start()
const context = require.context("controllers", true, /_controller\.js$/)
application.load(definitionsFromContext(context))

// Import and register stimulus-rails-nested-form
import NestedForm from "stimulus-rails-nested-form"
application.register("nested-form", NestedForm)

// Import and register all TailwindCSS Components
import { Alert, Dropdown, Modal, Tabs } from "tailwindcss-stimulus-components"
application.register('alert', Alert)
application.register('dropdown', Dropdown)
application.register('modal', Modal)
application.register('tabs', Tabs)
