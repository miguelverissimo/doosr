import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Calendar is rendered server-side
    // This controller can be extended for navigation, filtering, etc.
  }
}
