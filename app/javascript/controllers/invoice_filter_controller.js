import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["spinner", "frame"]

  connect() {
    // Set unpaid as active by default
    this.setActiveFilter("unpaid")

    // Listen for turbo frame events
    if (this.hasFrameTarget) {
      this.frameTarget.addEventListener("turbo:before-fetch-request", () => this.showSpinner())
      this.frameTarget.addEventListener("turbo:frame-load", () => this.hideSpinner())
    }
  }

  setActive(event) {
    // Extract filter type from the clicked element's href
    const url = new URL(event.currentTarget.href)
    const filter = url.searchParams.get("filter") || "unpaid"

    this.setActiveFilter(filter)
  }

  setActiveFilter(filter) {
    // Remove active styling from all filters
    const filters = ["unpaid", "paid", "all"]
    filters.forEach(f => {
      const element = document.getElementById(`filter_${f}`)
      if (element) {
        const badge = element.querySelector('[data-ruby-ui--badge-target="badge"]')
        if (badge) {
          if (f === filter) {
            // Add ring to active filter
            badge.classList.add("ring-2", "ring-offset-2", "ring-offset-background")
          } else {
            // Remove ring from inactive filters
            badge.classList.remove("ring-2", "ring-offset-2", "ring-offset-background")
          }
        }
      }
    })
  }

  showSpinner() {
    if (this.hasSpinnerTarget && this.hasFrameTarget) {
      this.spinnerTarget.classList.remove("hidden")
      this.frameTarget.classList.add("hidden")
    }
  }

  hideSpinner() {
    if (this.hasSpinnerTarget && this.hasFrameTarget) {
      this.spinnerTarget.classList.add("hidden")
      this.frameTarget.classList.remove("hidden")
    }
  }
}
