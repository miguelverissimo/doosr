import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    userId: String,
    selected: Array
  }

  connect() {
    // Initialize selected roles from the data attribute
    if (!this.hasSelectedValue) {
      this.selectedValue = []
    }
  }

  updateRoles(event) {
    // Get all checked checkboxes within this controller's scope
    const checkboxes = this.element.querySelectorAll('input[name="roles[]"]:checked')
    const selectedRoles = Array.from(checkboxes).map(cb => cb.value)

    // Update the roles via AJAX
    this.submitRoles(selectedRoles)
  }

  async submitRoles(roles) {
    // Show loading toast (consistent with form-loading controller)
    let loadingToastId = null
    if (window.toast) {
      loadingToastId = window.toast("Updating roles...", {
        type: "loading",
        description: "Please wait"
      })
    }

    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

      const response = await fetch(`/admin/users/${this.userIdValue}/update_roles`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": csrfToken
        },
        body: JSON.stringify({ roles: roles })
      })

      // Dismiss loading toast
      if (window.toast && window.toast.dismiss && loadingToastId) {
        window.toast.dismiss(loadingToastId)
      }

      if (response.ok) {
        const text = await response.text()
        // Turbo will automatically process the turbo-stream response (includes success toast)
        Turbo.renderStreamMessage(text)
      } else {
        throw new Error("Failed to update roles")
      }
    } catch (error) {
      console.error("Error updating roles:", error)

      // Dismiss loading toast
      if (window.toast && window.toast.dismiss && loadingToastId) {
        window.toast.dismiss(loadingToastId)
      }

      // Show error toast
      if (window.toast) {
        window.toast("Failed to update roles", { type: "error" })
      }
    }
  }
}
