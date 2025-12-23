import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "iban",
    "swiftBic",
    "routingNumber",
    "accountNumber"
  ]

  connect() {
    this.updateFieldStates()
  }

  onInput() {
    this.updateFieldStates()
  }

  updateFieldStates() {
    const hasIban = this.ibanTarget.value.trim().length > 0
    const hasSwiftBic = this.swiftBicTarget.value.trim().length > 0
    const hasRouting = this.routingNumberTarget.value.trim().length > 0
    const hasAccount = this.accountNumberTarget.value.trim().length > 0

    const ibanPairActive = hasIban || hasSwiftBic
    const routingPairActive = hasRouting || hasAccount

    // If IBAN/SWIFT pair is active, disable routing/account pair
    if (ibanPairActive) {
      this.routingNumberTarget.disabled = true
      this.accountNumberTarget.disabled = true
      this.routingNumberTarget.value = ""
      this.accountNumberTarget.value = ""
      this.routingNumberTarget.required = false
      this.accountNumberTarget.required = false
    } else {
      this.routingNumberTarget.disabled = false
      this.accountNumberTarget.disabled = false
    }

    // If routing/account pair is active, disable IBAN/SWIFT pair
    if (routingPairActive) {
      this.ibanTarget.disabled = true
      this.swiftBicTarget.disabled = true
      this.ibanTarget.value = ""
      this.swiftBicTarget.value = ""
      this.ibanTarget.required = false
      this.swiftBicTarget.required = false
    } else {
      this.ibanTarget.disabled = false
      this.swiftBicTarget.disabled = false
    }
  }
}

