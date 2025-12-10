import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["displayName", "editForm"]

  edit() {
    this.displayNameTarget.style.display = 'none'
    this.editFormTarget.style.display = 'flex'
  }

  cancel() {
    this.displayNameTarget.style.display = 'inline'
    this.editFormTarget.style.display = 'none'
  }
}
