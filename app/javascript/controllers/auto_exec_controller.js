import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { code: String }

  connect() {
    if (this.codeValue) {
      eval(this.codeValue)
      this.element.remove()
    }
  }
}
