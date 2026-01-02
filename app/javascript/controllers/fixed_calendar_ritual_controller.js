import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    month: Number,
    day: Number
  }

  connect() {
    console.log("Fixed calendar ritual controller connected for day", this.element.textContent.trim())
  }

  showRitual(event) {
    event.preventDefault()

    const url = `/fixed_calendar/ritual?month=${this.monthValue}&day=${this.dayValue}`

    fetch(url, {
      headers: {
        Accept: "text/vnd.turbo-stream.html"
      }
    })
      .then(response => response.text())
      .then(html => Turbo.renderStreamMessage(html))
      .catch(error => {
        console.error("Error fetching ritual:", error)
      })
  }

  showYearDayRitual(event) {
    event.preventDefault()

    const url = "/fixed_calendar/ritual?year_day=true"

    fetch(url, {
      headers: {
        Accept: "text/vnd.turbo-stream.html"
      }
    })
      .then(response => response.text())
      .then(html => Turbo.renderStreamMessage(html))
      .catch(error => {
        console.error("Error fetching year day ritual:", error)
      })
  }
}
