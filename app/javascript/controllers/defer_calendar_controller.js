import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["confirmButton", "buttonText"]
  static values = {
    itemId: String,
    dayId: String
  }

  connect() {
    console.log('Defer calendar controller connected')
    console.log('Button target:', this.confirmButtonTarget)
    console.log('Button text target:', this.buttonTextTarget)

    this.selectedDate = null

    // Listen for clicks on calendar days directly
    setTimeout(() => {
      const calendar = this.element.querySelector('[data-controller*="ruby-ui--calendar"]')
      console.log('Calendar element:', calendar)

      if (calendar) {
        // Listen for clicks on day buttons
        calendar.addEventListener('click', (e) => {
          const dayButton = e.target.closest('[data-action*="selectDay"]')
          if (dayButton && dayButton.dataset.day) {
            console.log('Day clicked:', dayButton.dataset.day)
            this.handleDateSelect(dayButton.dataset.day)
          }
        })
      }
    }, 100)
  }

  handleDateSelect(dateString) {
    console.log('Handling date select:', dateString)

    // Parse and store the date in YYYY-MM-DD format
    const date = new Date(dateString)
    this.selectedDate = date.toISOString().split('T')[0]
    console.log('Stored date in YYYY-MM-DD format:', this.selectedDate)

    // Update button text and enable it
    const formattedDate = date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    })

    console.log('Updating button to:', `Defer to ${formattedDate}`)
    this.buttonTextTarget.textContent = `Defer to ${formattedDate}`
    this.confirmButtonTarget.disabled = false
  }

  confirm() {
    console.log('Confirm clicked, selectedDate:', this.selectedDate)

    if (!this.selectedDate) {
      console.log('No date selected, returning')
      return
    }

    // Disable button and show loading
    this.confirmButtonTarget.disabled = true
    this.buttonTextTarget.textContent = 'Deferring...'

    // Submit the defer request
    this.submitDefer(this.selectedDate)
  }

  submitDefer(date) {
    console.log('Submitting defer for date:', date)

    const form = document.querySelector('#defer_calendar_form')
    console.log('Form found:', form)
    console.log('Form action:', form?.action)

    const url = form.action

    const formData = new FormData()
    formData.append('target_date', date)
    formData.append('_method', 'patch')
    if (this.dayIdValue) {
      formData.append('day_id', this.dayIdValue)
    }

    console.log('Making fetch request to:', url)
    console.log('FormData:', {
      target_date: date,
      _method: 'patch',
      day_id: this.dayIdValue
    })

    fetch(url, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'text/vnd.turbo-stream.html'
      },
      body: formData
    })
    .then(response => {
      console.log('Response status:', response.status)
      return response.text()
    })
    .then(html => {
      console.log('HTML response length:', html.length)
      console.log('HTML preview:', html.substring(0, 200))
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error('Error deferring item:', error)
      // Re-enable button on error
      const date = new Date(this.selectedDate)
      const formattedDate = date.toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        year: 'numeric'
      })
      this.buttonTextTarget.textContent = `Defer to ${formattedDate}`
      this.confirmButtonTarget.disabled = false
    })
  }
}

