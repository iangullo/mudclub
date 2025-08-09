// https://www.colby.so/posts/filtering-tables-with-rails-and-hotwire
//
// app/javascript/controllers/search_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
	static targets = [ "fsearch" ]

  connect() {
    this.timeout = null
  }

  search() {
    if (!this.hasFsearchTarget) return

    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.fsearchTarget.submit()
    }, 200)
  }
}
