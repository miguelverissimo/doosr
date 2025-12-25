import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dueDate"]

  updateDueDateMin(event) {
    const issueDate = event.target.value
    if (issueDate && this.hasDueDateTarget) {
      this.dueDateTarget.min = issueDate
      // If the current due date is before the issue date, clear it
      if (this.dueDateTarget.value && this.dueDateTarget.value < issueDate) {
        this.dueDateTarget.value = ""
      }
    }
  }
}

