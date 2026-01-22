import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    loadingMessage: { type: String, default: "Loading transactions..." }
  }

  async showTransactions(event) {
    event.preventDefault()
    event.stopPropagation()

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
        method: "GET",
        headers: {
          "Accept": "text/vnd.turbo-stream.html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      // Dismiss loading toast
      this.dismissLoadingToast(loadingToastId)

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      } else {
        window.toast && window.toast("Failed to load transactions", { type: "error" })
      }
    } catch (error) {
      this.dismissLoadingToast(loadingToastId)
      console.error("Failed to load recurring group transactions:", error)
      window.toast && window.toast("Failed to load transactions", { type: "error" })
    }
  }

  dismissLoadingToast(toastId) {
    if (window.toast && window.toast.dismiss && toastId) {
      window.toast.dismiss(toastId)
    }
  }
}
