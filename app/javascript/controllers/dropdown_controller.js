import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    // Bind hide method to this instance
    this.boundHide = this.hide.bind(this)
    this.boundHandleClick = this.handleClick.bind(this)
  }

  disconnect() {
    // Clean up event listeners
    document.removeEventListener("click", this.boundHandleClick)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    if (this.menuTarget.classList.contains("hidden")) {
      this.show()
    } else {
      this.hide()
    }
  }

  show() {
    this.menuTarget.classList.remove("hidden")
    // Add click listener to document to close on outside click
    // Delay slightly to avoid immediate close from the toggle click
    setTimeout(() => {
      document.addEventListener("click", this.boundHandleClick)
    }, 10)
  }

  hide() {
    this.menuTarget.classList.add("hidden")
    document.removeEventListener("click", this.boundHandleClick)
  }

  handleClick(event) {
    // Close dropdown if click is outside the dropdown element
    if (!this.element.contains(event.target)) {
      this.hide()
    }
  }
}
