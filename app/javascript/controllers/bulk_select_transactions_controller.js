import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selectAll", "checkbox", "bulkActions", "selectedCount", "selectedIds"]

  connect() {
    this.updateBulkActionsVisibility()
  }

  toggleAll() {
    const isChecked = this.selectAllTarget.checked
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = isChecked
    })
    this.updateBulkActionsVisibility()
  }

  toggleOne() {
    const allChecked = this.checkboxTargets.every(checkbox => checkbox.checked)
    const someChecked = this.checkboxTargets.some(checkbox => checkbox.checked)

    this.selectAllTarget.checked = allChecked
    this.selectAllTarget.indeterminate = someChecked && !allChecked

    this.updateBulkActionsVisibility()
  }

  updateBulkActionsVisibility() {
    const selectedCount = this.checkboxTargets.filter(checkbox => checkbox.checked).length

    if (selectedCount > 0) {
      this.bulkActionsTarget.classList.remove("hidden")
      this.selectedCountTarget.textContent = selectedCount
      this.updateSelectedIds()
    } else {
      this.bulkActionsTarget.classList.add("hidden")
    }
  }

  updateSelectedIds() {
    const selectedIds = this.checkboxTargets
      .filter(checkbox => checkbox.checked)
      .map(checkbox => checkbox.value)

    this.selectedIdsTarget.value = selectedIds.join(",")
  }

  clearSelection() {
    this.selectAllTarget.checked = false
    this.selectAllTarget.indeterminate = false
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = false
    })
    this.updateBulkActionsVisibility()
  }
}
