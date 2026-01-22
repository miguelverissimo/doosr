import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["spinner"]

  connect() {
    // Bind methods so we can remove listeners later
    this.boundShow = this.show.bind(this)
    this.boundHide = this.hide.bind(this)
    
    // Show spinner when navigation starts
    document.addEventListener("turbo:before-visit", this.boundShow)
    document.addEventListener("turbo:visit", this.boundShow)
    
    // Hide spinner on page load/navigation complete
    document.addEventListener("turbo:load", this.boundHide)
    document.addEventListener("turbo:render", this.boundHide)
    document.addEventListener("turbo:frame-load", this.boundHide)
  }

  disconnect() {
    document.removeEventListener("turbo:before-visit", this.boundShow)
    document.removeEventListener("turbo:visit", this.boundShow)
    document.removeEventListener("turbo:load", this.boundHide)
    document.removeEventListener("turbo:render", this.boundHide)
    document.removeEventListener("turbo:frame-load", this.boundHide)
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
