import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String
  }

  async showTransactions(event) {
    event.preventDefault()
    event.stopPropagation()

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
      console.error("Failed to load recurring group transactions:", error)
    }
  }
}
