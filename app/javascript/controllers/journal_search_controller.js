import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["spinner", "content"]

  connect() {
    this.element.addEventListener("turbo:before-stream-render", () => this.hideSpinner())
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
