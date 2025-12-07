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

      // Navigate to the day view for this date using Turbo
      const url = `/day?date=${selectedDate}`
      window.Turbo.visit(url)
    }
  }
}
