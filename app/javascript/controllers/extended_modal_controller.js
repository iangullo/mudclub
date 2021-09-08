import { Modal } from "tailwindcss-stimulus-components"

export default class ExtendedModal extends Modal {
  static targets = ["form", "errors"]

  connect() {
    super.connect()
  }

  handleSuccess({ detail: { success } }) {
    if (success) {
      super.close()
      this.clearErrors()
      this.formTarget.reset()
    }
  }

  clearErrors() {
    if (this.hasErrorsTarget) {
      this.errorsTarget.remove()
    }
  }
}
