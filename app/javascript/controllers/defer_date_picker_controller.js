import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["calendar", "options"]

  open(event) {
    event.preventDefault()

    // Toggle between options and calendar view
    const optionsView = document.querySelector('#defer_options_view')
    const calendarView = document.querySelector('#defer_calendar_view')

    if (optionsView && calendarView) {
      optionsView.classList.add('hidden')
      calendarView.classList.remove('hidden')
    }
  }

  selectDate(event) {
    event.preventDefault()
    const date = event.currentTarget.dataset.date

    // Get the form data
    const form = document.querySelector('form[action*="/defer"]')
    const dayId = form.querySelector('[name="day_id"]')?.value
    const url = form.action

    const formData = new FormData()
    formData.append('target_date', date)
    formData.append('_method', 'patch')
    if (dayId) {
      formData.append('day_id', dayId)
    }

    fetch(url, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'text/vnd.turbo-stream.html'
      },
      body: formData
    })
    .then(response => response.text())
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error('Error deferring item:', error)
    })
  }

  showOptions(event) {
    event.preventDefault()

    // Toggle back to options view
    const optionsView = document.querySelector('#defer_options_view')
    const calendarView = document.querySelector('#defer_calendar_view')

    if (optionsView && calendarView) {
      optionsView.classList.remove('hidden')
      calendarView.classList.add('hidden')
    }
  }
}

