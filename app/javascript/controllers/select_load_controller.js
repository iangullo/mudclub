// https://thoughtbot.com/blog/dynamic-forms-with-turbo
// (was "element" in the example)
// app/javascript/controllers/select_load_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "click" ]

  click() {
    this.clickTargets.forEach(target => target.click())
  }
}
