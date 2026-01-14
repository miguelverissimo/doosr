import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  cancelForm(event) {
    event.preventDefault()

    // Fetch the tab in its default state
    fetch("/settings/journal_protection?cancel_tab=true", {
      method: "GET",
      headers: {
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
    .then(response => response.text())
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
  }
}
