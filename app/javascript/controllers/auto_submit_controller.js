import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    message: { type: String, default: "Processing..." }
  }

  submit() {
    // Show loading toast
    if (window.toast) {
      this.loadingToastId = window.toast(this.messageValue, {
        type: "loading",
        description: "Please wait"
      })
    }
    this.element.requestSubmit()
  }

  disconnect() {
    // Dismiss loading toast when controller disconnects
    if (window.toast && window.toast.dismiss && this.loadingToastId) {
      window.toast.dismiss(this.loadingToastId)
    }
  }
}
