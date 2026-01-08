import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    journalId: Number,
    promptId: Number
  }

  respondToPrompt(event) {
    event.preventDefault()

    const journalId = this.journalIdValue
    const promptId = this.promptIdValue

    if (!journalId || !promptId) {
      console.error("Missing journalId or promptId")
      return
    }

    // Fetch fragment form with prompt_id parameter
    const url = `/journals/${journalId}/fragments/new?prompt_id=${promptId}`

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
        console.error("Error opening fragment dialog:", error)
        window.toast && window.toast("Failed to open dialog", { type: "error" })
      })
  }
}
