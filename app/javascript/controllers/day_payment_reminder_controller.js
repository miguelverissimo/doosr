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
    let actionsUrl = `/day_payment_reminders/${this.idValue}/actions`
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

    // Fetch the actions sheet for this day payment reminder
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
        console.error("Error opening payment reminder actions:", error)
        window.toast("Failed to open payment reminder actions", { type: "error" })
      })
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  confirmDelete(event) {
    event.preventDefault()
    event.stopPropagation()

    if (!confirm("Are you sure you want to remove this payment reminder from this day? This action cannot be undone.")) {
      return
    }

    // Show loading toast
    const loadingToastId = window.toast && window.toast("Removing payment reminder...", {
      type: "loading",
      description: "Please wait"
    })

    // Build URL with params
    const deleteUrl = `/day_payment_reminders/${this.idValue}`
    const params = new URLSearchParams()
    if (this.hasDayIdValue && this.dayIdValue) {
      params.append("day_id", this.dayIdValue)
    }
    if (this.hasListIdValue && this.listIdValue) {
      params.append("list_id", this.listIdValue)
    }

    const urlWithParams = params.toString() ? `${deleteUrl}?${params.toString()}` : deleteUrl

    // Close the drawer first
    const closeButton = document.querySelector('#day_payment_reminder_actions_sheet [data-action*="sheet-content#close"]')
    if (closeButton) {
      closeButton.click()
    }

    // Delete the day payment reminder
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
          window.toast("Payment reminder removed successfully", { type: "success" })
        }
      })
      .catch(error => {
        // Dismiss loading toast
        if (window.toast && window.toast.dismiss && loadingToastId) {
          window.toast.dismiss(loadingToastId)
        }

        console.error("Error deleting payment reminder:", error)
        if (window.toast) {
          window.toast("Failed to remove payment reminder", { type: "error" })
        }
      })
  }
}
