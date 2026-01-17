import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropdown"]
  static values = {
    url: { type: String, default: "/notifications" },
    open: { type: Boolean, default: false }
  }

  connect() {
    this.handleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.handleClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.handleClickOutside)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.openValue) {
      this.close()
    } else {
      this.fetchAndOpen()
    }
  }

  async fetchAndOpen() {
    try {
      const response = await fetch(this.urlValue, {
        headers: {
          "Accept": "text/vnd.turbo-stream.html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
        this.openValue = true
      }
    } catch (error) {
      console.error("Failed to fetch notifications:", error)
    }
  }

  close() {
    const dropdown = this.element.querySelector("#notifications_dropdown")
    if (dropdown) {
      dropdown.remove()
    }
    this.openValue = false
  }

  handleClickOutside(event) {
    if (!this.openValue) return

    const dropdown = this.element.querySelector("#notifications_dropdown")
    const isClickInsideBell = this.element.contains(event.target)
    const isClickInsideDropdown = dropdown && dropdown.contains(event.target)

    if (!isClickInsideBell && !isClickInsideDropdown) {
      this.close()
    }
  }
}
