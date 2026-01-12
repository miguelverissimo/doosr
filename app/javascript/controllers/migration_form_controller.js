import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="migration-form"
export default class extends Controller {
  handleSubmit(event) {
    // Show loading toast
    const toastId = window.toast && window.toast("Migrating items...", {
      type: "loading",
      description: "Please wait"
    })

    // Store the toast ID to dismiss later
    this.toastId = toastId
  }

  handleSubmitEnd(event) {
    // Dismiss loading toast
    if (this.toastId && window.toast && window.toast.dismiss) {
      window.toast.dismiss(this.toastId)
      this.toastId = null
    }

    // Remove the modal from DOM after submission
    const modalDiv = document.getElementById("day_migration_modal")
    if (modalDiv) {
      modalDiv.remove()
    }
  }
}
