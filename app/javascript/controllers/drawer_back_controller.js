import { Controller } from "@hotwired/stimulus"

// Handles navigation back to the main actions sheet in a drawer
export default class extends Controller {
  static values = {
    url: String
  }

  async goBack(event) {
    event.preventDefault()

    try {
      const response = await fetch(this.urlValue, {
        method: "GET",
        headers: {
          "Accept": "text/vnd.turbo-stream.html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      }
    } catch (error) {
      console.error("Failed to navigate back:", error)
    }
  }
}
