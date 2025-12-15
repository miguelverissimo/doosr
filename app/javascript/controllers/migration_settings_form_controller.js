import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="migration-settings-form"
export default class extends Controller {
  submit(event) {
    // Show loading toast
    const toastId = window.toast && window.toast("Saving migration settings...", {
      type: "loading",
      description: "Please wait"
    })

    // Store the toast ID to dismiss later
    this.toastId = toastId

    // Listen for submission end to dismiss toast
    const handleSubmitEnd = () => {
      if (this.toastId && window.toast) {
        window.toast.dismiss(this.toastId)
      }
      document.removeEventListener("turbo:submit-end", handleSubmitEnd)
    }

    document.addEventListener("turbo:submit-end", handleSubmitEnd)
  }
}
