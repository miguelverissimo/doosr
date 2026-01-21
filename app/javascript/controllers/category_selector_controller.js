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

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      }
    } catch (error) {
      console.error("Failed to update category:", error)
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

    try {
      const response = await fetch(this.editUrlValue, {
        method: "GET",
        headers: {
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": csrfToken
        }
      })

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      }
    } catch (error) {
      console.error("Failed to open edit dialog:", error)
    }
  }
}
