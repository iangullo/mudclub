// https://www.colby.so/posts/filtering-tables-with-rails-and-hotwire
//
// app/javascript/controllers/search_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "f" ]

  search() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.formTarget.requestSubmit()
    }, 200)
  }
}
