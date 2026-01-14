import { Controller } from "@hotwired/stimulus"

// Manages journal unlock state and session token handling
// - Stores session token in localStorage on successful unlock
// - Includes token in X-Journal-Session header on journal requests
// - Clears token on logout
// - Dispatches events for locked/unlocked state changes
export default class extends Controller {
  static values = {
    requiresUnlock: { type: Boolean, default: false }
  }

  static TOKEN_KEY = "journal_session_token"

  connect() {
    // Listen for unlock events from the unlock form
    this.handleUnlockedBound = this.handleUnlocked.bind(this)
    window.addEventListener("journal:unlocked", this.handleUnlockedBound)

    // Intercept Turbo requests to add journal session header
    this.beforeFetchBound = this.beforeFetch.bind(this)
    document.addEventListener("turbo:before-fetch-request", this.beforeFetchBound)

    // Clear token on logout
    this.handleLogoutBound = this.handleLogout.bind(this)
    document.addEventListener("turbo:before-fetch-request", this.checkLogoutRequest.bind(this))
  }

  disconnect() {
    window.removeEventListener("journal:unlocked", this.handleUnlockedBound)
    document.removeEventListener("turbo:before-fetch-request", this.beforeFetchBound)
  }

  // Handle successful unlock event (dispatched from unlock form response)
  handleUnlocked() {
    // Token is already stored via script injection from server response
    // Dispatch event for any listening components
    this.dispatch("stateChanged", { detail: { locked: false } })
  }

  // Add X-Journal-Session header to journal-related requests
  beforeFetch(event) {
    const token = this.getToken()
    if (!token) return

    const url = event.detail.url.toString()

    // Only add header for journal-related requests
    if (this.isJournalRequest(url)) {
      event.detail.fetchOptions.headers["X-Journal-Session"] = token
    }
  }

  // Check if the request is a logout request
  checkLogoutRequest(event) {
    const url = event.detail.url.toString()

    // Check for Devise sign out path
    if (url.includes("/users/sign_out")) {
      this.clearToken()
    }
  }

  // Clear token on logout
  handleLogout() {
    this.clearToken()
  }

  // Check if URL is journal-related
  isJournalRequest(url) {
    return url.includes("/journals")
  }

  // Get session token from localStorage
  getToken() {
    return localStorage.getItem(this.constructor.TOKEN_KEY)
  }

  // Store session token
  setToken(token) {
    localStorage.setItem(this.constructor.TOKEN_KEY, token)
  }

  // Clear session token
  clearToken() {
    localStorage.removeItem(this.constructor.TOKEN_KEY)
    this.dispatch("stateChanged", { detail: { locked: true } })
  }

  // Check if journal is currently unlocked
  isUnlocked() {
    return this.getToken() !== null
  }

  // Check if journal is currently locked
  isLocked() {
    return !this.isUnlocked()
  }

  // Open unlock dialog
  openUnlockDialog() {
    fetch("/journals/unlock", {
      headers: {
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
      .then(response => response.text())
      .then(html => {
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, "text/html")
        const template = doc.querySelector("turbo-stream template")

        if (template) {
          const content = template.content.cloneNode(true)
          document.body.appendChild(content)
        }
      })
      .catch(error => {
        console.error("Error opening unlock dialog:", error)
        window.toast && window.toast("Failed to open unlock dialog", { type: "error" })
      })
  }
}
