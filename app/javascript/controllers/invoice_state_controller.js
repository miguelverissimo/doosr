import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="invoice-state"
// Handles state changes for invoices with toast notifications
export default class extends Controller {
  static values = {
    state: String
  }

  submit(event) {
    // Show loading toast immediately
    const stateMessages = {
      draft: 'Marking invoice as draft...',
      sent: 'Marking invoice as sent...',
      paid: 'Marking invoice as paid...'
    }
    
    const message = stateMessages[this.stateValue] || 'Updating invoice...'
    if (window.toast) {
      this.loadingToastId = window.toast(message, {
        type: 'loading',
        description: 'Please wait'
      })
    }
  }

  connect() {
    // Listen for turbo:submit-end to show success/error toasts
    this.element.addEventListener('turbo:submit-end', this.handleSubmitEnd.bind(this))
  }

  disconnect() {
    this.element.removeEventListener('turbo:submit-end', this.handleSubmitEnd.bind(this))
  }

  handleSubmitEnd(event) {
    // Dismiss loading toast
    if (window.toast && window.toast.dismiss && this.loadingToastId) {
      window.toast.dismiss(this.loadingToastId)
      this.loadingToastId = null
    }

    // The server will send its own toast message via turbo stream,
    // so we don't need to show another one here
    // This prevents duplicate toasts
  }
}

