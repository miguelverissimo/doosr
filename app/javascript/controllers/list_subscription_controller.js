import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

export default class extends Controller {
  static values = { listId: Number }

  connect() {
    console.log("List subscription controller connecting with list_id:", this.listIdValue)

    this.subscription = consumer.subscriptions.create(
      { channel: "ListChannel", list_id: this.listIdValue },
      {
        connected: () => {
          console.log("✅ Connected to list channel", this.listIdValue)
        },

        disconnected: () => {
          console.log("❌ Disconnected from list channel", this.listIdValue)
        },

        rejected: () => {
          console.log("🚫 Subscription rejected for list", this.listIdValue)
        },

        received: (data) => {
          console.log("📨 Received list update:", data)
          // The data contains turbo stream HTML that will update the page
          if (data.html) {
            Turbo.renderStreamMessage(data.html)

            // Notify autocomplete to refresh titles from DOM after a short delay
            setTimeout(() => {
              this.dispatch("listUpdated")
            }, 100)
          }
        }
      }
    )
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }
}
