import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]
  static values = { debounce: { type: Number, default: 300 } }

  connect() {
    this.timeout = null
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  search() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    this.timeout = setTimeout(() => {
      this.formTarget.requestSubmit()
    }, this.debounceValue)
  }
}
