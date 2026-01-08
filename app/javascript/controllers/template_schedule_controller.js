import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dayOfMonthField", "weekdaysField"]

  connect() {
    this.updateFields()
  }

  updateFields() {
    const select = this.element.querySelector('select[name="journal_prompt_template[schedule_rule][frequency]"]')
    if (!select) return

    const frequency = select.value

    // Hide all conditional fields
    if (this.hasDayOfMonthFieldTarget) {
      this.dayOfMonthFieldTarget.classList.add("hidden")
    }
    if (this.hasWeekdaysFieldTarget) {
      this.weekdaysFieldTarget.classList.add("hidden")
    }

    // Show relevant field based on frequency
    if (frequency === "day_of_month" && this.hasDayOfMonthFieldTarget) {
      this.dayOfMonthFieldTarget.classList.remove("hidden")
    } else if (frequency === "specific_weekdays" && this.hasWeekdaysFieldTarget) {
      this.weekdaysFieldTarget.classList.remove("hidden")
    }
  }
}
