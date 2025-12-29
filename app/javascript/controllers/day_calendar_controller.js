import { Controller } from "@hotwired/stimulus"

// Controller for handling calendar day navigation
export default class extends Controller {
  connect() {
    // Listen for clicks on calendar day buttons
    this.element.addEventListener("click", this.handleDayClick.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("click", this.handleDayClick.bind(this))
  }

  handleDayClick(e) {
    // Check if the clicked element is a calendar day button
    const dayButton = e.target.closest('button[name="day"]')
    if (dayButton && dayButton.dataset.day) {
      e.preventDefault()
      const selectedDate = dayButton.dataset.day

      // Convert to YYYY-MM-DD format
      const date = new Date(selectedDate)
      const formattedDate = date.toISOString().split('T')[0]

      // Show loading spinner
      const navLoader = document.querySelector('[data-controller~="nav-loader"]')
      if (navLoader) {
        const controller = this.application.getControllerForElementAndIdentifier(navLoader, "nav-loader")
        if (controller) {
          controller.show()
        }
      }

      // Navigate to the day view for this date using Turbo
      const url = `/day?date=${formattedDate}`
      window.Turbo.visit(url)
    }
  }
}
