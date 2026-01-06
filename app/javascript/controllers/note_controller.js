import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    id: Number,
    dayId: Number,
    listId: Number
  }

  openActions(event) {
    event.preventDefault()
    event.stopPropagation()

    // Build URL with context params
    let actionsUrl = `/notes/${this.idValue}/actions`
    const params = new URLSearchParams()

    if (this.hasDayIdValue && this.dayIdValue) {
      params.append("day_id", this.dayIdValue)
    }
    if (this.hasListIdValue && this.listIdValue) {
      params.append("list_id", this.listIdValue)
    }

    if (params.toString()) {
      actionsUrl += `?${params.toString()}`
    }

    // Fetch the actions sheet for this note
    fetch(actionsUrl, {
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
        console.error("Error opening note actions:", error)
        window.toast("Failed to open note actions", { type: "error" })
      })
  }

  openDebug(event) {
    event.preventDefault()
    event.stopPropagation()

    const debugUrl = `/notes/${this.idValue}/debug`
    fetch(debugUrl, {
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
        console.error("Error opening debug:", error)
      })
  }

  confirmDelete(event) {
    event.preventDefault()
    event.stopPropagation()

    if (!confirm("Are you sure you want to delete this note? This action cannot be undone.")) {
      return
    }

    // Show loading toast
    const loadingToastId = window.toast && window.toast("Deleting note...", {
      type: "loading",
      description: "Please wait"
    })

    // Build URL with params
    const deleteUrl = `/notes/${this.idValue}`
    const params = new URLSearchParams()
    if (this.hasDayIdValue && this.dayIdValue) {
      params.append("day_id", this.dayIdValue)
    }
    if (this.hasListIdValue && this.listIdValue) {
      params.append("list_id", this.listIdValue)
    }

    const urlWithParams = params.toString() ? `${deleteUrl}?${params.toString()}` : deleteUrl

    // Close the drawer first
    const closeButton = document.querySelector('#note_actions_sheet [data-action*="sheet-content#close"]')
    if (closeButton) {
      closeButton.click()
    }

    // Delete the note
    fetch(urlWithParams, {
      method: "DELETE",
      headers: {
        "Accept": "text/vnd.turbo-stream.html",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      }
    })
      .then(response => response.text())
      .then(html => {
        // Dismiss loading toast
        if (window.toast && window.toast.dismiss && loadingToastId) {
          window.toast.dismiss(loadingToastId)
        }

        // Parse and apply turbo streams
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, "text/html")
        const templates = doc.querySelectorAll("turbo-stream template")

        templates.forEach(template => {
          const content = template.content.cloneNode(true)
          const turboStream = template.parentElement
          const action = turboStream.getAttribute("action")
          const target = turboStream.getAttribute("target")

          if (action === "update") {
            const targetEl = document.getElementById(target)
            if (targetEl) {
              targetEl.innerHTML = ""
              targetEl.appendChild(content)
            }
          } else if (action === "remove") {
            const targetEl = document.getElementById(target)
            if (targetEl) {
              targetEl.remove()
            }
          }
        })

        // Show success toast
        if (window.toast) {
          window.toast("Note deleted successfully", { type: "success" })
        }
      })
      .catch(error => {
        // Dismiss loading toast
        if (window.toast && window.toast.dismiss && loadingToastId) {
          window.toast.dismiss(loadingToastId)
        }

        console.error("Error deleting note:", error)
        if (window.toast) {
          window.toast("Failed to delete note", { type: "error" })
        }
      })
  }
}
