import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["datetimeInput", "submitButton"]

  connect() {
    // Validate on connect to set initial state
    this.validateDateTime()
  }

  setPreset(event) {
    event.preventDefault()

    const preset = event.currentTarget.dataset.preset
    const now = new Date()
    let targetDate

    switch (preset) {
      case "in_1_hour":
        targetDate = new Date(now.getTime() + 60 * 60 * 1000)
        break
      case "tomorrow_9am":
        targetDate = new Date(now)
        targetDate.setDate(targetDate.getDate() + 1)
        targetDate.setHours(9, 0, 0, 0)
        break
      case "in_3_days":
        targetDate = new Date(now)
        targetDate.setDate(targetDate.getDate() + 3)
        targetDate.setHours(9, 0, 0, 0)
        break
      default:
        return
    }

    // Format as datetime-local value (YYYY-MM-DDTHH:MM)
    const formatted = this.formatDatetimeLocal(targetDate)
    this.datetimeInputTarget.value = formatted
    
    // Validate after setting preset
    this.validateDateTime()
  }

  validateDateTime() {
    const value = this.datetimeInputTarget.value
    
    if (!value || value.trim() === "") {
      this.submitButtonTarget.disabled = true
      return
    }

    // Parse the datetime-local value
    const selectedDate = new Date(value)
    const now = new Date()

    // Check if the selected date is in the past
    if (selectedDate <= now) {
      this.submitButtonTarget.disabled = true
      return
    }

    // Valid and in the future
    this.submitButtonTarget.disabled = false
  }

  formatDatetimeLocal(date) {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, "0")
    const day = String(date.getDate()).padStart(2, "0")
    const hours = String(date.getHours()).padStart(2, "0")
    const minutes = String(date.getMinutes()).padStart(2, "0")
    return `${year}-${month}-${day}T${hours}:${minutes}`
  }
}
