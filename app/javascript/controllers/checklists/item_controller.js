import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submitForm(event) {
    // Submit the form when checkbox changes
    this.element.requestSubmit()
  }
}
