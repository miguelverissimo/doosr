import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["rowsContainer", "rowTemplate", "totalAmount", "remainingAmount"]
  static values = {
    transactionAmount: Number
  }

  connect() {
    this.updateRemainingAmount()
  }

  addRow(event) {
    event.preventDefault()
    const template = this.rowTemplateTarget.content.cloneNode(true)
    const row = template.querySelector("[data-row]")
    const index = this.rowsContainerTarget.children.length

    // Update field names with new index
    row.querySelectorAll("select, input").forEach(field => {
      if (field.name) {
        field.name = field.name.replace(/\[\d*\]/, `[${index}]`)
      }
    })

    this.rowsContainerTarget.appendChild(template)
    this.updateRemainingAmount()
  }

  removeRow(event) {
    event.preventDefault()
    const row = event.target.closest("[data-row]")
    if (this.rowsContainerTarget.children.length > 1) {
      row.remove()
      this.updateRemainingAmount()
    }
  }

  updateRemainingAmount() {
    if (!this.hasRemainingAmountTarget) return

    const total = this.transactionAmountValue
    let allocated = 0

    this.rowsContainerTarget.querySelectorAll("input[type='number']").forEach(input => {
      const value = parseFloat(input.value) || 0
      allocated += value
    })

    const remaining = total - allocated
    this.remainingAmountTarget.textContent = remaining.toFixed(2)

    if (remaining < 0) {
      this.remainingAmountTarget.classList.add("text-destructive")
      this.remainingAmountTarget.classList.remove("text-muted-foreground")
    } else {
      this.remainingAmountTarget.classList.remove("text-destructive")
      this.remainingAmountTarget.classList.add("text-muted-foreground")
    }
  }
}
