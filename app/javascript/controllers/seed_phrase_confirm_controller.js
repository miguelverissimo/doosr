import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "submitButton"]

  connect() {
    this.updateSubmitButton()
  }

  toggleSubmit() {
    this.updateSubmitButton()
  }

  updateSubmitButton() {
    if (this.hasCheckboxTarget && this.hasSubmitButtonTarget) {
      const isChecked = this.checkboxTarget.checked
      this.submitButtonTarget.disabled = !isChecked
    }
  }
}
