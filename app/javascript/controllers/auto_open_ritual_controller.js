import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    month: Number,
    day: Number,
    type: String
  }

  connect() {
    console.log("Auto open ritual controller connected")
    console.log("Type:", this.typeValue)
    console.log("Month:", this.monthValue)
    console.log("Day:", this.dayValue)
    
    // Automatically trigger the ritual modal after a short delay
    // to ensure the page is fully loaded
    setTimeout(() => {
      this.openRitual()
    }, 300)
  }

  openRitual() {
    let url

    if (this.typeValue === "year_day") {
      url = "/fixed_calendar/ritual?year_day=true"
    } else if (this.typeValue === "regular" && this.hasMonthValue && this.hasDayValue) {
      url = `/fixed_calendar/ritual?month=${this.monthValue}&day=${this.dayValue}`
    } else {
      console.warn("Cannot open ritual: invalid type or missing month/day values")
      return
    }

    console.log("Opening ritual with URL:", url)

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
}

