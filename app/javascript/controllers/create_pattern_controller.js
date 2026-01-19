import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String
  }

  async openDialog(event) {
    event.preventDefault()
    event.stopPropagation()

    try {
      // Pass current filter/pagination params to the dialog
      const currentParams = new URLSearchParams(window.location.search)
      const dialogUrl = new URL(this.urlValue, window.location.origin)
      currentParams.forEach((value, key) => {
        dialogUrl.searchParams.append(key, value)
      })

      const response = await fetch(dialogUrl.toString(), {
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
      console.error("Error loading pattern dialog:", error)
      if (window.toast) {
        window.toast("Failed to load pattern dialog", { type: "error" })
      }
    }
  }
}
