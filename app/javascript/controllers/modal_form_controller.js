import { Controller } from "@hotwired/stimulus"

// Universal controller for forms inside modals/dialogs
// Handles:
// 1. Loading toast on submit
// 2. Dismiss modal on successful submission
// 3. Success toast on successful submission
export default class extends Controller {
  static values = {
    loadingMessage: { type: String, default: "Processing..." },
    successMessage: { type: String, default: "Saved successfully" }
  }

  connect() {
    this.element.addEventListener("submit", this.handleSubmit.bind(this))
    this.element.addEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("submit", this.handleSubmit.bind(this))
    this.element.removeEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))

    // Dismiss any remaining toast
    if (window.toast && window.toast.dismiss && this.loadingToastId) {
      window.toast.dismiss(this.loadingToastId)
    }
  }

  handleSubmit(event) {
    // Show loading toast
    if (window.toast) {
      this.loadingToastId = window.toast(this.loadingMessageValue, {
        type: "loading",
        description: "Please wait"
      })
    }
  }

  handleSubmitEnd(event) {
    // Dismiss loading toast
    if (window.toast && window.toast.dismiss && this.loadingToastId) {
      window.toast.dismiss(this.loadingToastId)
      this.loadingToastId = null
    }

    // If submission was successful (not an error response), dismiss the dialog
    const { success, fetchResponse } = event.detail
    if (success && fetchResponse && fetchResponse.response.ok) {
      // Small delay to allow turbo streams to process first
      setTimeout(() => {
        this.dismissModal()
      }, 100)
    }
  }

  selectTemplate(event) {
    event.preventDefault()
    const templateText = event.currentTarget.dataset.templateText
    const textarea = this.element.querySelector("textarea")
    if (textarea && templateText) {
      textarea.value = templateText
      textarea.focus()
    }
  }

  cancelDialog(event) {
    event.preventDefault()
    // Find the dialog element and remove it from DOM
    const dialog = this.element.closest('[data-controller*="ruby-ui--dialog"]')
    if (dialog) {
      dialog.remove()
    }
  }

  dismissModal() {
    const dialogElement = this.element.closest('[data-controller*="ruby-ui--dialog"]')

    if (dialogElement) {
      const dialogController = this.application.getControllerForElementAndIdentifier(
        dialogElement,
        'ruby-ui--dialog'
      )

      if (dialogController) {
        if (dialogController.close) {
          dialogController.close()
          return
        } else if (dialogController.dismiss) {
          dialogController.dismiss()
          return
        } else if (dialogController.hide) {
          dialogController.hide()
          return
        }
      }
    }

    const alertDialogElement = this.element.closest('[data-controller*="ruby-ui--alert-dialog"]')

    if (alertDialogElement) {
      const alertDialogController = this.application.getControllerForElementAndIdentifier(
        alertDialogElement,
        'ruby-ui--alert-dialog'
      )

      if (alertDialogController) {
        if (alertDialogController.close) {
          alertDialogController.close()
          return
        } else if (alertDialogController.dismiss) {
          alertDialogController.dismiss()
          return
        }
      }
    }
  }
}
