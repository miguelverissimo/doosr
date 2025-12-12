import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["titleInput", "itemType", "typeIcon"]
  static values = {
    currentType: { type: String, default: "completable" } // completable or section
  }

  connect() {
    this.updateTypeIcon()
  }

  cycleType(e) {
    e.preventDefault()
    // Toggle between completable and section
    this.currentTypeValue = this.currentTypeValue === "completable" ? "section" : "completable"
    this.itemTypeTarget.value = this.currentTypeValue
    this.updateTypeIcon()
  }

  updateTypeIcon() {
    const icon = this.typeIconTarget

    // Clear existing paths
    icon.innerHTML = ""

    if (this.currentTypeValue === "completable") {
      // Completable: circle (checkbox)
      const circle = document.createElementNS("http://www.w3.org/2000/svg", "circle")
      circle.setAttribute("cx", "12")
      circle.setAttribute("cy", "12")
      circle.setAttribute("r", "10")
      icon.appendChild(circle)
    } else {
      // Section: hash symbol
      const line1 = document.createElementNS("http://www.w3.org/2000/svg", "line")
      line1.setAttribute("x1", "4")
      line1.setAttribute("x2", "20")
      line1.setAttribute("y1", "9")
      line1.setAttribute("y2", "9")
      icon.appendChild(line1)

      const line2 = document.createElementNS("http://www.w3.org/2000/svg", "line")
      line2.setAttribute("x1", "4")
      line2.setAttribute("x2", "20")
      line2.setAttribute("y1", "15")
      line2.setAttribute("y2", "15")
      icon.appendChild(line2)

      const line3 = document.createElementNS("http://www.w3.org/2000/svg", "line")
      line3.setAttribute("x1", "10")
      line3.setAttribute("x2", "8")
      line3.setAttribute("y1", "3")
      line3.setAttribute("y2", "21")
      icon.appendChild(line3)

      const line4 = document.createElementNS("http://www.w3.org/2000/svg", "line")
      line4.setAttribute("x1", "16")
      line4.setAttribute("x2", "14")
      line4.setAttribute("y1", "3")
      line4.setAttribute("y2", "21")
      icon.appendChild(line4)
    }
  }

  submit(e) {
    // Show loading toast based on item type
    if (window.toast) {
      const itemType = this.currentTypeValue === "section" ? "section" : "item"
      const message = this.currentTypeValue === "section" ? "Creating section..." : "Creating item..."

      this.loadingToastId = window.toast(message, {
        type: "loading",
        description: "Please wait"
      })
    }
    // Allow form submission, Turbo will handle it
  }

  clearForm() {
    // Dismiss loading toast if it exists
    if (window.toast && window.toast.dismiss && this.loadingToastId) {
      window.toast.dismiss(this.loadingToastId)
      this.loadingToastId = null
    }

    // Dispatch event with the title that was just added (before clearing)
    const addedTitle = this.titleInputTarget.value
    if (addedTitle) {
      this.dispatch("itemAdded", { detail: { title: addedTitle } })
    }

    // Clear the input after successful submission
    this.titleInputTarget.value = ""
    this.currentTypeValue = "completable"
    this.itemTypeTarget.value = "completable"
    this.updateTypeIcon()
    this.titleInputTarget.focus()
  }
}
