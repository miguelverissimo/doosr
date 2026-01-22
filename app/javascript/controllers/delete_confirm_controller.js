import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    message: String,
    loadingMessage: { type: String, default: "Deleting..." }
  }

  async confirm(event) {
    event.preventDefault()

    // For now, use native confirm. This can be enhanced with a custom dialog.
    if (window.confirm(this.messageValue || "Are you sure?")) {
      const token = document.querySelector('meta[name="csrf-token"]')?.content

      // Show loading toast
      let loadingToastId
      if (window.toast) {
        loadingToastId = window.toast(this.loadingMessageValue, {
          type: "loading",
          description: "Please wait"
        })
      }

      try {
        const response = await fetch(this.urlValue, {
          method: "DELETE",
          headers: {
            "Accept": "text/vnd.turbo-stream.html",
            "X-CSRF-Token": token
          }
        })

        // Dismiss loading toast
        if (window.toast && window.toast.dismiss && loadingToastId) {
          window.toast.dismiss(loadingToastId)
        }

        if (response.ok) {
          const html = await response.text()
          Turbo.renderStreamMessage(html)
          // Show success toast
          window.toast && window.toast("Deleted successfully", { type: "success" })
        } else {
          window.toast && window.toast("Delete failed", { type: "error" })
        }
      } catch (error) {
        // Dismiss loading toast
        if (window.toast && window.toast.dismiss && loadingToastId) {
          window.toast.dismiss(loadingToastId)
        }
        console.error("Delete failed:", error)
        window.toast && window.toast("Delete failed", { type: "error" })
      }
    }
  }
}
