import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    date: String
  }

  open(e) {
    console.log("Opening ephemeries for date:", this.dateValue)

    const url = `/ephemeries?date=${encodeURIComponent(this.dateValue)}`

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
        console.log("HTML received:", html)
      }
    })
    .catch(error => {
      console.error("Error fetching ephemeries:", error)
    })
  }
}
