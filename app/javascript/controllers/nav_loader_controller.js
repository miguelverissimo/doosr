import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["spinner"]

  connect() {
    // Hide spinner on page load/navigation complete
    document.addEventListener("turbo:load", () => this.hide())
    document.addEventListener("turbo:render", () => this.hide())
  }

  show() {
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.remove("hidden")
    }
  }

  hide() {
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.add("hidden")
    }
  }
}
