import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    dayId: Number
  }

  connect() {
    console.log("Day note controller connected, dayId:", this.dayIdValue)
  }

  openDialog() {
    const url = `/days/${this.dayIdValue}/notes/new`

    fetch(url, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
      .then(response => response.text())
      .then(html => {
        // Parse the turbo-stream response and extract the template content
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, "text/html")
        const template = doc.querySelector("turbo-stream template")

        if (template) {
          // Get the content from the template
          const content = template.content.cloneNode(true)
          // Append directly to body
          document.body.appendChild(content)
        } else {
          console.error("No template found in turbo-stream")
        }
      })
      .catch(error => {
        console.error("Error opening note dialog:", error)
        window.toast("Failed to open note dialog", { type: "error" })
      })
  }
}
