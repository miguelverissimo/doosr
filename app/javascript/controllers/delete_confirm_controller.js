import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    message: String
  }

  async confirm(event) {
    event.preventDefault()

    // For now, use native confirm. This can be enhanced with a custom dialog.
    if (window.confirm(this.messageValue || "Are you sure?")) {
      const token = document.querySelector('meta[name="csrf-token"]')?.content

      try {
        const response = await fetch(this.urlValue, {
          method: "DELETE",
          headers: {
            "Accept": "text/vnd.turbo-stream.html",
            "X-CSRF-Token": token
          }
        })

        if (response.ok) {
          const html = await response.text()
          Turbo.renderStreamMessage(html)
        }
      } catch (error) {
        console.error("Delete failed:", error)
      }
    }
  }
}
