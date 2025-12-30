import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["spinner", "content"]

  connect() {
    // Listen for turbo stream render completion on document
    this.boundHideSpinner = this.hideSpinner.bind(this)
    document.addEventListener("turbo:before-stream-render", this.boundHideSpinner)
  }

  disconnect() {
    document.removeEventListener("turbo:before-stream-render", this.boundHideSpinner)
  }

  showSpinner() {
    if (this.hasSpinnerTarget && this.hasContentTarget) {
      this.spinnerTarget.classList.remove("hidden")
      this.contentTarget.classList.add("hidden")
    }
  }

  hideSpinner() {
    if (this.hasSpinnerTarget && this.hasContentTarget) {
      this.spinnerTarget.classList.add("hidden")
      this.contentTarget.classList.remove("hidden")
    }
  }
}
