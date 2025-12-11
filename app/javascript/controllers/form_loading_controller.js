import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    message: { type: String, default: "Processing..." }
  }

  connect() {
    // Listen for form submission
    this.element.addEventListener("submit", this.handleSubmit.bind(this))
    this.element.addEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))
  }

  handleSubmit(e) {
    // Show loading toast
    if (window.toast) {
      this.loadingToastId = window.toast(this.messageValue, {
        type: "loading",
        description: "Please wait"
      })
    }
  }

  handleSubmitEnd(e) {
    // Dismiss loading toast
    if (window.toast && window.toast.dismiss && this.loadingToastId) {
      window.toast.dismiss(this.loadingToastId)
      this.loadingToastId = null
    }
  }

  disconnect() {
    // Clean up event listeners
    this.element.removeEventListener("submit", this.handleSubmit.bind(this))
    this.element.removeEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))

    // Dismiss any remaining toast
    if (window.toast && window.toast.dismiss && this.loadingToastId) {
      window.toast.dismiss(this.loadingToastId)
    }
  }
}
