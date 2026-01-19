import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String
  }

  async openDialog(event) {
    event.preventDefault()
    event.stopPropagation()

    try {
      const response = await fetch(this.urlValue, {
        headers: {
          "Accept": "text/vnd.turbo-stream.html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const html = await response.text()

      const parser = new DOMParser()
      const doc = parser.parseFromString(html, "text/html")
      const template = doc.querySelector("template")

      if (template) {
        document.body.appendChild(template.content.cloneNode(true))
      }
    } catch (error) {
      console.error("Error loading edit dialog:", error)
      if (window.toast) {
        window.toast("Failed to load edit dialog", { type: "error" })
      }
    }
  }
}
