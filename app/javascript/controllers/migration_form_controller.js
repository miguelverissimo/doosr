import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="migration-form"
export default class extends Controller {
  submit(event) {
    // Show loading toast
    const toastId = window.toast && window.toast("Migrating items...", {
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

  cancel(event) {
    event.preventDefault()

    // Try to dispatch ESC key to close the dialog (RubyUI dialogs typically close on ESC)
    document.dispatchEvent(new KeyboardEvent('keydown', {
      key: 'Escape',
      code: 'Escape',
      keyCode: 27,
      bubbles: true,
      cancelable: true
    }))

    // Also try to remove dialog elements directly
    setTimeout(() => {
      // Clear the modal div
      const modalDiv = document.getElementById("day_migration_modal")
      if (modalDiv) {
        modalDiv.innerHTML = ""
      }

      // Remove any dialog overlays/backdrops
      document.querySelectorAll('[data-controller*="ruby-ui--dialog"]').forEach(el => {
        el.remove()
      })

      // Remove any elements with data-state="open" that might be overlays
      document.querySelectorAll('[data-state="open"]').forEach(el => {
        el.remove()
      })
    }, 100)
  }
}
