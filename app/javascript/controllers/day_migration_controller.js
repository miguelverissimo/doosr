import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String
  }

  openDialog(event) {
    const url = this.urlValue

    fetch(url, {
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
        } else {
          console.error("No template found in turbo-stream")
        }
      })
      .catch(error => {
        console.error("Error opening migration dialog:", error)
        window.toast && window.toast("Failed to open dialog", { type: "error" })
      })
  }
}
