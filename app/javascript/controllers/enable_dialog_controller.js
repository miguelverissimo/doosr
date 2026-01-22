import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    loadingMessage: { type: String, default: "Loading..." }
  }

  openDialog(event) {
    if (event) event.preventDefault()

    const url = this.urlValue

    // Show loading toast
    if (window.toast) {
      this.loadingToastId = window.toast(this.loadingMessageValue, {
        type: "loading",
        description: "Please wait"
      })
    }

    fetch(url, {
      headers: {
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
      .then(response => response.text())
      .then(html => {
        // Dismiss loading toast
        this.dismissLoadingToast()

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
        // Dismiss loading toast
        this.dismissLoadingToast()

        console.error("Error opening dialog:", error)
        window.toast && window.toast("Failed to open dialog", { type: "error" })
      })
  }

  dismissLoadingToast() {
    if (window.toast && window.toast.dismiss && this.loadingToastId) {
      window.toast.dismiss(this.loadingToastId)
      this.loadingToastId = null
    }
  }

  disconnect() {
    this.dismissLoadingToast()
  }
}
