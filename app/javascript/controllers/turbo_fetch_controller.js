import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    loadingMessage: { type: String, default: "Loading..." }
  }

  async load(event) {
    if (event) event.preventDefault()

    // Show loading toast
    let loadingToastId
    if (window.toast) {
      loadingToastId = window.toast(this.loadingMessageValue, {
        type: "loading",
        description: "Please wait"
      })
    }

    try {
      const response = await fetch(this.urlValue, {
        headers: {
          "Accept": "text/vnd.turbo-stream.html"
        }
      })

      // Dismiss loading toast
      this.dismissLoadingToast(loadingToastId)

      if (response.ok) {
        const html = await response.text()

        // Parse the turbo stream response and execute actions manually
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, "text/html")
        const streams = doc.querySelectorAll("turbo-stream")

        streams.forEach(stream => {
          const action = stream.getAttribute("action")
          const target = stream.getAttribute("target")
          const template = stream.querySelector("template")

          if (template && target) {
            const targetElement = document.getElementById(target)
            if (targetElement) {
              if (action === "replace") {
                targetElement.replaceWith(template.content.cloneNode(true))
              } else if (action === "append") {
                targetElement.appendChild(template.content.cloneNode(true))
              } else if (action === "prepend") {
                targetElement.prepend(template.content.cloneNode(true))
              } else if (action === "remove") {
                targetElement.remove()
              }
            }
          }
        })
      } else {
        window.toast && window.toast("Failed to load content", { type: "error" })
      }
    } catch (error) {
      this.dismissLoadingToast(loadingToastId)
      console.error("Error fetching turbo stream:", error)
      window.toast && window.toast("Failed to load content", { type: "error" })
    }
  }

  dismissLoadingToast(toastId) {
    if (window.toast && window.toast.dismiss && toastId) {
      window.toast.dismiss(toastId)
    }
  }
}
