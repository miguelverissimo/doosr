import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["taxBracket", "exemptionMotive", "grossUnitPrice", "unitPriceWithTax"]
  static values = { taxBrackets: Object }

  connect() {
    this.updateExemptionMotiveField()
    this.calculateUnitPriceWithTax()
    this.isSubmitting = false
  }

  submit(event) {
    if (this.isSubmitting) {
      event.preventDefault()
      return
    }
    this.isSubmitting = true

    // Find submit button and disable it
    const submitButton = this.element.querySelector('button[type="submit"]')
    if (submitButton) {
      submitButton.disabled = true
    }
  }

  // Reset on turbo:submit-end to allow retry if there's an error
  reset() {
    this.isSubmitting = false
    const submitButton = this.element.querySelector('button[type="submit"]')
    if (submitButton) {
      submitButton.disabled = false
    }
  }

  onTaxBracketChange() {
    this.updateExemptionMotiveField()
    this.calculateUnitPriceWithTax()
  }

  calculateUnitPriceWithTax() {
    const grossUnitPriceValue = parseFloat(this.grossUnitPriceTarget.value) || 0
    const taxBracketId = this.taxBracketTarget.value
    const unitPriceWithTaxField = this.unitPriceWithTaxTarget

    if (!taxBracketId || grossUnitPriceValue === 0) {
      unitPriceWithTaxField.value = ""
      return
    }

    const taxBracket = this.taxBracketsValue[taxBracketId]
    if (!taxBracket) {
      unitPriceWithTaxField.value = ""
      return
    }

    const taxPercentage = taxBracket.percentage || 0
    const unitPriceWithTax = grossUnitPriceValue * (1 + taxPercentage / 100)
    
    // Round to 2 decimal places
    unitPriceWithTaxField.value = unitPriceWithTax.toFixed(2)
  }

  updateExemptionMotiveField() {
    const taxBracketId = this.taxBracketTarget.value
    const exemptionMotiveField = this.exemptionMotiveTarget

    if (!taxBracketId) {
      exemptionMotiveField.disabled = true
      exemptionMotiveField.required = false
      exemptionMotiveField.value = ""
      return
    }

    const taxBracket = this.taxBracketsValue[taxBracketId]
    const isZeroPercent = taxBracket && taxBracket.percentage === 0

    if (isZeroPercent) {
      exemptionMotiveField.disabled = false
      exemptionMotiveField.required = true
    } else {
      exemptionMotiveField.disabled = true
      exemptionMotiveField.required = false
      exemptionMotiveField.value = ""
    }
  }
}

