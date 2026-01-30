import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    vapidPublicKey: String,
    subscribeUrl: String
  }

  connect() {
    this.promptForPermission()
  }

  async promptForPermission() {
    if (!("Notification" in window) || !("serviceWorker" in navigator)) return
    if (Notification.permission !== "default") return

    const permission = await Notification.requestPermission()

    if (permission === "granted") {
      await this.subscribe()
    }
  }

  async subscribe() {
    try {
      if (!this.vapidPublicKeyValue || this.vapidPublicKeyValue.trim() === "") return

      const registration = await navigator.serviceWorker.ready
      if (!("pushManager" in registration)) return

      const existingSubscription = await registration.pushManager.getSubscription()
      if (existingSubscription) {
        await existingSubscription.unsubscribe()
      }

      const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.urlBase64ToUint8Array(this.vapidPublicKeyValue)
      })

      const subscriptionData = subscription.toJSON()

      await fetch(this.subscribeUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
          "Accept": "application/json"
        },
        body: JSON.stringify({ subscription: subscriptionData })
      })
    } catch (error) {
      console.error("Auto push subscription failed:", error)
    }
  }

  urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - base64String.length % 4) % 4)
    const base64 = (base64String + padding).replace(/-/g, "+").replace(/_/g, "/")
    const rawData = window.atob(base64)
    const outputArray = new Uint8Array(rawData.length)
    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i)
    }
    return outputArray
  }
}
