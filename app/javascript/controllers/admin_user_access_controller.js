import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle(event) {
    // Submit the form when checkbox is toggled
    // form-loading controller handles the toast
    const form = event.target.closest("form")

    if (form) {
      form.requestSubmit()
    } else {
      console.error("No form found for checkbox")
    }
  }
}
