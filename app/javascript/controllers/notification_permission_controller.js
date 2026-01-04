import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "subscribeButton", "unsubscribeButton"]
  static values = {
    vapidPublicKey: String,
    subscribeUrl: String,
    unsubscribeUrl: String
  }

  connect() {
    this.checkPermissionStatus()
  }

  async checkPermissionStatus() {
    if (!('Notification' in window)) {
      this.updateStatus('not-supported', 'Notifications not supported')
      return
    }

    const permission = Notification.permission

    if (permission === 'granted') {
      const isSubscribed = await this.checkSubscription()
      if (isSubscribed) {
        this.updateStatus('subscribed', 'Notifications enabled')
      } else {
        this.updateStatus('granted', 'Permission granted, not subscribed')
      }
    } else if (permission === 'denied') {
      this.updateStatus('denied', 'Notifications blocked')
    } else {
      this.updateStatus('default', 'Notifications not enabled')
    }
  }

  async requestPermission() {
    if (!('Notification' in window)) {
      window.toast('Notifications not supported in this browser', { type: 'error' })
      return
    }

    const permission = await Notification.requestPermission()

    if (permission === 'granted') {
      await this.subscribe()
    } else {
      window.toast('Notification permission denied', { type: 'error' })
      this.updateStatus('denied', 'Permission denied')
    }
  }

  async subscribe() {
    try {
      // Check if service worker is supported
      if (!('serviceWorker' in navigator)) {
        throw new Error('Service Workers not supported')
      }

      // Wait for service worker to be ready
      console.log('Waiting for service worker to be ready...')
      const registration = await navigator.serviceWorker.ready
      console.log('Service worker ready, state:', registration.active?.state)

      // Check if push manager is available
      if (!('pushManager' in registration)) {
        throw new Error('Push notifications not supported')
      }

      // Check for existing subscription
      const existingSubscription = await registration.pushManager.getSubscription()
      if (existingSubscription) {
        console.log('Unsubscribing from existing subscription...')
        await existingSubscription.unsubscribe()
      }

      // Subscribe to push notifications
      console.log('Subscribing to push notifications...')
      const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.urlBase64ToUint8Array(this.vapidPublicKeyValue)
      })

      console.log('Push subscription successful:', subscription)
      const subscriptionData = subscription.toJSON()

      const response = await fetch(this.subscribeUrlValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Accept': 'text/vnd.turbo-stream.html'
        },
        body: JSON.stringify({ subscription: subscriptionData })
      })

      if (response.ok) {
        this.updateStatus('subscribed', 'Notifications enabled')
        window.toast('Notifications enabled successfully', { type: 'success' })
      } else {
        throw new Error('Failed to save subscription')
      }
    } catch (error) {
      console.error('Subscription failed:', error)

      let errorMessage = 'Failed to enable notifications'
      if (error.message.includes('not supported')) {
        errorMessage = error.message
      } else if (error.name === 'AbortError') {
        errorMessage = 'Push service error. Are you using HTTPS or localhost?'
      } else if (error.name === 'InvalidAccessError') {
        errorMessage = 'Invalid VAPID key. Please check server configuration.'
      }

      window.toast(errorMessage, { type: 'error', description: error.message })
    }
  }

  async unsubscribe() {
    try {
      const registration = await navigator.serviceWorker.ready
      const subscription = await registration.pushManager.getSubscription()

      if (subscription) {
        await subscription.unsubscribe()

        await fetch(this.unsubscribeUrlValue, {
          method: 'DELETE',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
            'Accept': 'text/vnd.turbo-stream.html'
          },
          body: JSON.stringify({ endpoint: subscription.endpoint })
        })
      }

      this.updateStatus('default', 'Notifications disabled')
      window.toast('Notifications disabled', { type: 'success' })
    } catch (error) {
      console.error('Unsubscribe failed:', error)
      window.toast('Failed to disable notifications', { type: 'error' })
    }
  }

  async checkSubscription() {
    try {
      const registration = await navigator.serviceWorker.ready
      const subscription = await registration.pushManager.getSubscription()
      return !!subscription
    } catch (error) {
      console.error('Check subscription failed:', error)
      return false
    }
  }

  updateStatus(state, message) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
      this.statusTarget.dataset.state = state
    }

    // Show/hide buttons based on state
    if (this.hasSubscribeButtonTarget && this.hasUnsubscribeButtonTarget) {
      if (state === 'subscribed') {
        this.subscribeButtonTarget.classList.add('hidden')
        this.unsubscribeButtonTarget.classList.remove('hidden')
      } else if (state === 'default' || state === 'granted') {
        this.subscribeButtonTarget.classList.remove('hidden')
        this.unsubscribeButtonTarget.classList.add('hidden')
      }
    }
  }

  urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - base64String.length % 4) % 4)
    const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/')
    const rawData = window.atob(base64)
    const outputArray = new Uint8Array(rawData.length)

    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i)
    }

    return outputArray
  }
}
