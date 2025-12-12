import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    id: Number,
    dayId: Number,
    listId: Number,
    isPublicList: Boolean,
    type: String
  }

  openSheet(e) {
    // Don't open sheet if clicking on a form/button (like checkbox)
    if (e.target.closest("form") || e.target.closest("button")) {
      return
    }

    // Don't open sheet if we're in moving mode
    if (sessionStorage.getItem('movingItemId')) {
      return
    }

    console.log("Opening sheet for item:", this.idValue)

    // Fetch the actions sheet via Turbo
    let url = `/items/${this.idValue}/actions`
    const params = []

    if (this.hasDayIdValue && this.dayIdValue) {
      params.push(`day_id=${this.dayIdValue}`)
    }

    if (this.hasListIdValue && this.listIdValue) {
      params.push(`list_id=${this.listIdValue}`)
    }

    if (this.hasIsPublicListValue && this.isPublicListValue) {
      params.push(`is_public_list=true`)
    }

    if (params.length > 0) {
      url += `?${params.join('&')}`
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

  stopPropagation(e) {
    e.stopPropagation()
  }

  submitForm(e) {
    const form = e.target.closest("form")
    if (form) {
      form.requestSubmit()
    }
  }
}
