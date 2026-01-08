import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    id: Number,
    dayId: Number
  }

  navigateToJournal(event) {
    // Stop propagation so clicking the icon doesn't trigger openSheet on parent
    event.stopPropagation()
    // Let the link navigate normally (don't preventDefault)
  }

  openSheet(event) {
    // Don't open sheet if clicking on a form/button
    if (event.target.closest("form") || event.target.closest("button")) {
      return
    }

    // Don't open sheet if clicking on a link element
    if (event.target.tagName === "A" || event.target.closest("a")) {
      return
    }

    // Fetch the actions sheet via Turbo
    const url = `/day_journal_links/${this.idValue}/actions?day_id=${this.dayIdValue}`

    fetch(url, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
    .then(response => {
      return response.text()
    })
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
      console.error("Error fetching sheet:", error)
    })
  }

  openDebug(e) {
    const journalId = e.currentTarget.dataset.journalId || this.idValue
    const dayId = e.currentTarget.dataset.dayId || this.dayIdValue

    console.log("Debug clicked - Journal ID:", journalId, "Day ID:", dayId)

    const url = `/day_journal_links/${journalId}/debug?day_id=${dayId}`

    console.log("Fetching debug URL:", url)

    fetch(url, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
    .then(response => {
      console.log("Debug response status:", response.status)
      return response.text()
    })
    .then(html => {
      console.log("Debug HTML received:", html.substring(0, 200))
      // Parse and insert manually
      const parser = new DOMParser()
      const doc = parser.parseFromString(html, "text/html")
      const template = doc.querySelector("turbo-stream template")

      if (template) {
        const content = template.content.cloneNode(true)
        document.body.appendChild(content)
        console.log("Debug script appended to body")
      } else {
        console.error("No template found in debug response")
      }
    })
    .catch(error => {
      console.error("Error fetching debug:", error)
    })
  }
}
