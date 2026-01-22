import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    editUrl: String
  }

  static targets = ["select", "badge"]

  async change(event) {
    const categoryId = event.target.value
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    if (this.hasBadgeTarget) {
      this.badgeTarget.classList.add("opacity-50")
    }

    // Show loading toast
    let loadingToastId
    if (window.toast) {
      loadingToastId = window.toast("Updating category...", {
        type: "loading",
        description: "Please wait"
      })
    }

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": csrfToken
        },
        body: JSON.stringify({
          bank_transaction: {
            category_id: categoryId === "" ? null : categoryId
          }
        })
      })

      // Dismiss loading toast
      this.dismissLoadingToast(loadingToastId)

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      } else {
        window.toast && window.toast("Failed to update category", { type: "error" })
        if (this.hasBadgeTarget) {
          this.badgeTarget.classList.remove("opacity-50")
        }
      }
    } catch (error) {
      this.dismissLoadingToast(loadingToastId)
      console.error("Failed to update category:", error)
      window.toast && window.toast("Failed to update category", { type: "error" })
      if (this.hasBadgeTarget) {
        this.badgeTarget.classList.remove("opacity-50")
      }
    }
  }

  async openEditDialog(event) {
    event.preventDefault()
    event.stopPropagation()

    if (!this.hasEditUrlValue) return

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    // Show loading toast
    let loadingToastId
    if (window.toast) {
      loadingToastId = window.toast("Loading...", {
        type: "loading",
        description: "Please wait"
      })
    }

    try {
      const response = await fetch(this.editUrlValue, {
        method: "GET",
        headers: {
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": csrfToken
        }
      })

      // Dismiss loading toast
      this.dismissLoadingToast(loadingToastId)

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      } else {
        window.toast && window.toast("Failed to load dialog", { type: "error" })
      }
    } catch (error) {
      this.dismissLoadingToast(loadingToastId)
      console.error("Failed to open edit dialog:", error)
      window.toast && window.toast("Failed to load dialog", { type: "error" })
    }
  }

  dismissLoadingToast(toastId) {
    if (window.toast && window.toast.dismiss && toastId) {
      window.toast.dismiss(toastId)
    }
  }
}
