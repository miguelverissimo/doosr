import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    id: Number,
    dayId: Number,
    type: String
  }

  openSheet(e) {
    // Don't open sheet if clicking on a form/button (like checkbox)
    if (e.target.closest("form") || e.target.closest("button")) {
      return
    }

    console.log("Opening sheet for item:", this.idValue)

    // Fetch the actions sheet via Turbo
    let url = `/items/${this.idValue}/actions`
    if (this.hasDayIdValue && this.dayIdValue) {
      url += `?day_id=${this.dayIdValue}`
    }

    console.log("Fetching:", url)

    fetch(url, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
    .then(response => {
      console.log("Response status:", response.status)
      return response.text()
    })
    .then(html => {
      console.log("Received HTML length:", html.length)

      // Parse the turbo-stream response and extract the template content
      const parser = new DOMParser()
      const doc = parser.parseFromString(html, 'text/html')
      const template = doc.querySelector('turbo-stream template')

      if (template) {
        console.log("Template found, inserting content")
        // Get the content from the template
        const content = template.content.cloneNode(true)
        // Append directly to body
        document.body.appendChild(content)
        console.log("Content appended to body")
      } else {
        console.error("No template found in turbo-stream")
      }
    })
    .catch(error => {
      console.error("Error fetching sheet:", error)
    })
  }

  openDebug(e) {
    const itemId = e.currentTarget.dataset.itemIdValue || this.idValue
    const url = `/items/${itemId}/debug`

    console.log("Opening debug for item:", itemId)

    fetch(url, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
    .then(response => response.text())
    .then(html => {
      console.log("Debug HTML received, length:", html.length)

      // Parse and insert manually
      const parser = new DOMParser()
      const doc = parser.parseFromString(html, 'text/html')
      const template = doc.querySelector('turbo-stream template')

      if (template) {
        const content = template.content.cloneNode(true)
        document.body.appendChild(content)
        console.log("Debug content appended")
      }
    })
    .catch(error => {
      console.error("Error fetching debug:", error)
    })
  }

  toggle(e) {
    // The form will handle submission via Turbo
    // We just need to make sure the form submits
    const form = e.target.closest("form")
    if (form) {
      form.requestSubmit()
    }
  }
}
