// https://www.colby.so/posts/filtering-tables-with-rails-and-hotwire
//
// app/javascript/controllers/search_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
	static targets = [ "fsearch" ]

	search() {
		clearTimeout(this.timeout)
		this.timeout = setTimeout(() => {
      const form = document.querySelector(`[data-target="${this.identifier}.fsearch"]`);
      form?.submit();
		}, 200);
	}
}
