import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "manevHQuantityInput",
    "manevOnCallQuantityInput",
    "tokenQuantityInput",
    "manevHAmount",
    "manevOnCallAmount",
    "tokenAmount",
    "totalDisplay",
    "receiptValue",
    "manevHQuantity",
    "manevHValueWithTax",
    "manevOnCallQuantity",
    "manevOnCallValueWithTax",
    "tokenQuantity",
    "tokenValueWithTax"
  ]
  static values = {
    manevHUnitPrice: Number,
    manevOnCallUnitPrice: Number,
    tokenUnitPrice: Number
  }

  connect() {
    this.updateAll()
  }

  onQuantityChange() {
    this.updateAll()
  }

  updateAll() {
    // Get quantities from inputs
    const manevHQuantity = parseInt(this.manevHQuantityInputTarget?.value || 0) || 0
    const manevOnCallQuantity = parseInt(this.manevOnCallQuantityInputTarget?.value || 0) || 0
    const tokenQuantity = parseInt(this.tokenQuantityInputTarget?.value || 0) || 0

    // Calculate amounts in cents
    const manevHAmount = manevHQuantity * this.manevHUnitPriceValue
    const manevOnCallAmount = manevOnCallQuantity * this.manevOnCallUnitPriceValue
    const tokenAmount = tokenQuantity * this.tokenUnitPriceValue

    // Calculate total
    const totalAmount = manevHAmount + manevOnCallAmount + tokenAmount

    // Update amount displays
    if (this.hasManevHAmountTarget) {
      this.manevHAmountTarget.textContent = this.formatCurrency(manevHAmount / 100)
    }
    if (this.hasManevOnCallAmountTarget) {
      this.manevOnCallAmountTarget.textContent = this.formatCurrency(manevOnCallAmount / 100)
    }
    if (this.hasTokenAmountTarget) {
      this.tokenAmountTarget.textContent = this.formatCurrency(tokenAmount / 100)
    }

    // Update total display
    if (this.hasTotalDisplayTarget) {
      this.totalDisplayTarget.textContent = this.formatCurrency(totalAmount / 100)
    }

    // Update receipt value (in units, not cents)
    if (this.hasReceiptValueTarget) {
      this.receiptValueTarget.value = (totalAmount / 100).toFixed(2)
    }

    // Update hidden fields for form submission
    if (this.hasManevHQuantityTarget) {
      this.manevHQuantityTarget.value = manevHQuantity.toString()
    }
    if (this.hasManevHValueWithTaxTarget) {
      this.manevHValueWithTaxTarget.value = manevHAmount.toString()
    }
    if (this.hasManevOnCallQuantityTarget) {
      this.manevOnCallQuantityTarget.value = manevOnCallQuantity.toString()
    }
    if (this.hasManevOnCallValueWithTaxTarget) {
      this.manevOnCallValueWithTaxTarget.value = manevOnCallAmount.toString()
    }
    if (this.hasTokenQuantityTarget) {
      this.tokenQuantityTarget.value = tokenQuantity.toString()
    }
    if (this.hasTokenValueWithTaxTarget) {
      this.tokenValueWithTaxTarget.value = tokenAmount.toString()
    }
  }

  formatCurrency(value) {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "EUR",
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(value)
  }
}

