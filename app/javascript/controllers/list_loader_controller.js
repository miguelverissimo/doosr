import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["spinner", "content"]

  connect() {
    // On page load, show spinner first, then hide it and show content
    // Use a small delay to ensure the spinner is visible
    setTimeout(() => {
      this.hideSpinner()
    }, 100)
  }

  hideSpinner() {
    if (this.hasSpinnerTarget && this.hasContentTarget) {
      this.spinnerTarget.classList.add("hidden")
      this.contentTarget.classList.remove("hidden")
    }
  }
}
