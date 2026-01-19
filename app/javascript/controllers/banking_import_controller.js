import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

// Handles real-time import notifications via ActionCable
export default class extends Controller {
  static values = {
    userId: Number
  }

  connect() {
    this.setupSubscription()
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  setupSubscription() {
    if (!this.userIdValue) return

    const consumer = createConsumer()
    this.subscription = consumer.subscriptions.create(
      { channel: "BankingImportChannel" },
      {
        connected: () => {
          console.log("Connected to BankingImportChannel")
        },
        disconnected: () => {
          console.log("Disconnected from BankingImportChannel")
        },
        received: (data) => {
          this.handleImportResult(data)
        }
      }
    )
  }

  handleImportResult(data) {
    const { success, imported, skipped, errors } = data

    // Show toast with import results
    if (window.toast) {
      if (success) {
        const message = `Import complete: ${imported} transactions imported`
        const description = skipped > 0 ? `${skipped} duplicates skipped` : null
        window.toast(message, { type: "success", description })
      } else {
        const message = "Import failed"
        const description = errors && errors.length > 0 ? errors[0] : "Unknown error"
        window.toast(message, { type: "error", description })
      }
    }

    // Refresh the transactions table by resubmitting the filter form
    const filterForm = document.querySelector('form[action*="/banking"]')
    if (filterForm && filterForm.requestSubmit) {
      filterForm.requestSubmit()
    } else {
      // Fallback: reload the page
      window.location.reload()
    }
  }
}
