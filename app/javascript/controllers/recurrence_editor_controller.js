import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="recurrence-editor"
export default class extends Controller {
  static targets = ["ruleInput", "intervalContainer", "intervalInput", "weeklyContainer", "form"]

  connect() {
    this.selectedFrequency = this.parseCurrentRule().frequency || "none"
    this.selectedWeekdays = this.parseCurrentRule().days_of_week || []
    this.interval = this.parseCurrentRule().interval || 3
  }

  selectFrequency(event) {
    const frequency = event.params.frequency
    this.selectedFrequency = frequency

    // Update button visual states
    this.updateFrequencyButtons(event.currentTarget)

    // Update UI to show/hide relevant containers
    this.updateVisibility()

    // Update the rule
    this.updateRule()
  }

  updateFrequencyButtons(selectedButton) {
    // Find all frequency buttons
    const buttons = this.element.querySelectorAll('[data-action*="selectFrequency"]')

    buttons.forEach(button => {
      // Remove selected styles
      button.classList.remove("bg-primary", "text-primary-foreground")
      button.classList.add("border", "bg-background", "hover:bg-accent")
    })

    // Add selected styles to clicked button
    selectedButton.classList.remove("border", "bg-background", "hover:bg-accent")
    selectedButton.classList.add("bg-primary", "text-primary-foreground")
  }

  toggleWeekday(event) {
    const day = parseInt(event.params.day)
    const button = event.currentTarget

    if (this.selectedWeekdays.includes(day)) {
      this.selectedWeekdays = this.selectedWeekdays.filter(d => d !== day)
      // Remove selected styles
      button.classList.remove("bg-primary", "text-primary-foreground")
      button.classList.add("border", "bg-background", "hover:bg-accent")
    } else {
      this.selectedWeekdays.push(day)
      this.selectedWeekdays.sort((a, b) => a - b)
      // Add selected styles
      button.classList.remove("border", "bg-background", "hover:bg-accent")
      button.classList.add("bg-primary", "text-primary-foreground")
    }

    // Update the rule
    this.updateRule()
  }

  updateInterval(event) {
    this.interval = parseInt(event.target.value) || 3
    this.updateRule()
  }

  updateVisibility() {
    // Show/hide interval container
    if (this.hasIntervalContainerTarget) {
      if (this.selectedFrequency === "every_n_days") {
        this.intervalContainerTarget.classList.remove("hidden")
      } else {
        this.intervalContainerTarget.classList.add("hidden")
      }
    }

    // Show/hide weekly container
    if (this.hasWeeklyContainerTarget) {
      if (this.selectedFrequency === "weekly") {
        this.weeklyContainerTarget.classList.remove("hidden")
      } else {
        this.weeklyContainerTarget.classList.add("hidden")
      }
    }
  }

  updateRule() {
    let rule

    if (this.selectedFrequency === "none") {
      rule = "none"
    } else if (this.selectedFrequency === "daily") {
      rule = JSON.stringify({ frequency: "daily" })
    } else if (this.selectedFrequency === "every_weekday") {
      rule = JSON.stringify({ frequency: "every_weekday" })
    } else if (this.selectedFrequency === "every_n_days") {
      // Get current interval from input if available
      if (this.hasIntervalInputTarget) {
        this.interval = parseInt(this.intervalInputTarget.value) || 3
      }
      rule = JSON.stringify({ frequency: "every_n_days", interval: this.interval })
    } else if (this.selectedFrequency === "weekly") {
      rule = JSON.stringify({ frequency: "weekly", days_of_week: this.selectedWeekdays })
    } else if (this.selectedFrequency === "monthly") {
      rule = JSON.stringify({ frequency: "monthly" })
    } else if (this.selectedFrequency === "yearly") {
      rule = JSON.stringify({ frequency: "yearly" })
    }

    if (this.hasRuleInputTarget) {
      this.ruleInputTarget.value = rule
    }
  }

  parseCurrentRule() {
    if (!this.hasRuleInputTarget) return { frequency: "none" }

    const ruleValue = this.ruleInputTarget.value

    if (!ruleValue || ruleValue === "none") {
      return { frequency: "none" }
    }

    try {
      return JSON.parse(ruleValue)
    } catch (e) {
      return { frequency: "none" }
    }
  }
}
