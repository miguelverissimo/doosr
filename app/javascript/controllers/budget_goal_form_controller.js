import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["goalType", "categoryField", "period", "paymentMonthsField", "amountHint"]

  connect() {
    this.toggleGoalType()
    this.togglePeriod()
  }

  toggleGoalType() {
    const goalType = this.goalTypeTarget.value

    if (goalType === "category_limit") {
      this.categoryFieldTarget.classList.remove("hidden")
    } else {
      this.categoryFieldTarget.classList.add("hidden")
    }
  }

  togglePeriod() {
    const period = this.periodTarget.value

    if (period === "custom") {
      this.paymentMonthsFieldTarget.classList.remove("hidden")
    } else {
      this.paymentMonthsFieldTarget.classList.add("hidden")
    }

    // Update amount hint text
    if (this.hasAmountHintTarget) {
      if (period === "quarterly" || period === "custom") {
        this.amountHintTarget.textContent = "Amount needed per payment period"
      } else {
        this.amountHintTarget.textContent = "The amount per period (will be prorated for progress tracking)"
      }
    }
  }
}
