import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

// Handles real-time recurring detection notifications via ActionCable
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
      { channel: "BankingRecurringChannel" },
      {
        connected: () => {
          console.log("Connected to BankingRecurringChannel")
        },
        disconnected: () => {
          console.log("Disconnected from BankingRecurringChannel")
        },
        received: (data) => {
          this.handleDetectionResult(data)
        }
      }
    )
  }

  handleDetectionResult(data) {
    const { success, groups_created, groups_updated, transactions_linked, errors } = data

    // Show toast with detection results
    if (window.toast) {
      if (success) {
        const parts = []
        if (groups_created > 0) parts.push(`${groups_created} new pattern${groups_created !== 1 ? 's' : ''}`)
        if (groups_updated > 0) parts.push(`${groups_updated} updated`)
        if (transactions_linked > 0) parts.push(`${transactions_linked} transaction${transactions_linked !== 1 ? 's' : ''} linked`)

        const message = parts.length > 0
          ? `Detection complete: ${parts.join(', ')}`
          : "Detection complete: No new patterns found"
        window.toast(message, { type: "success" })
      } else {
        const message = "Detection failed"
        const description = errors && errors.length > 0 ? errors[0] : "Unknown error"
        window.toast(message, { type: "error", description })
      }
    }

    // Refresh the recurring groups list if the dialog is open
    const recurringContent = document.getElementById("recurring_groups_content")
    if (recurringContent) {
      this.refreshRecurringList()
    }
  }

  async refreshRecurringList() {
    try {
      const response = await fetch("/banking/recurring_groups?back_to_list=true", {
        headers: {
          "Accept": "text/vnd.turbo-stream.html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      }
    } catch (error) {
      console.error("Failed to refresh recurring list:", error)
    }
  }
}
