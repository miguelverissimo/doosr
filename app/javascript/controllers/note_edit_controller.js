import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String
  }

  openDialog(event) {
    if (event) event.preventDefault()

    fetch(this.urlValue, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
      .then(response => response.text())
      .then(html => {
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, "text/html")
        const template = doc.querySelector("turbo-stream template")

        if (template) {
          const content = template.content.cloneNode(true)
          document.body.appendChild(content)
        }
      })
      .catch(error => {
        console.error("Error opening note edit dialog:", error)
        window.toast && window.toast("Failed to open dialog", { type: "error" })
      })
  }
}
