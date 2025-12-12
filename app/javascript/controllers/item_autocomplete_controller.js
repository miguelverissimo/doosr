import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropdown", "results"]
  static values = { titles: Array }

  connect() {
    console.log("Item autocomplete controller connected with titles:", this.titlesValue)
    this.boundClickOutside = this.clickOutside.bind(this)
  }

  addTitle(event) {
    const newTitle = event.detail.title
    if (newTitle && !this.titlesValue.some(t => t.toLowerCase() === newTitle.toLowerCase())) {
      this.titlesValue = [...this.titlesValue, newTitle].sort()
      console.log("Added title to autocomplete:", newTitle, "Total titles:", this.titlesValue.length)
    }
  }

  refreshTitlesFromDOM() {
    // Extract all item titles from the DOM (scan the items list)
    const itemsList = document.getElementById('items_list')
    if (!itemsList) return

    const titles = []
    // Find all items - they have data-item-id-value attribute
    const items = itemsList.querySelectorAll('[data-item-id-value]')

    items.forEach(item => {
      // Get the title from the item - it's in a <p> or <h3> tag
      const titleElement = item.querySelector('p:not([class*="text-xs"]), h3')
      if (titleElement) {
        const title = titleElement.textContent.trim()
        if (title && !titles.includes(title)) {
          titles.push(title)
        }
      }
    })

    // Update the titles value
    this.titlesValue = titles.sort()
    console.log("Refreshed autocomplete titles from DOM:", this.titlesValue.length, "titles")
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside)
  }

  search(event) {
    const query = this.inputTarget.value.trim().toLowerCase()

    if (query.length === 0) {
      this.hideDropdown()
      return
    }

    // Filter titles that match the query (case-insensitive)
    const matches = this.titlesValue.filter(title =>
      title.toLowerCase().includes(query)
    )

    if (matches.length === 0) {
      this.hideDropdown()
      return
    }

    this.showDropdown(matches)
  }

  showDropdown(matches) {
    this.resultsTarget.innerHTML = ""

    matches.forEach(title => {
      const item = document.createElement("div")
      item.className = "px-3 py-2 text-sm cursor-pointer hover:bg-accent transition-colors"
      item.textContent = title
      item.dataset.action = "click->item-autocomplete#selectTitle"
      item.dataset.title = title
      this.resultsTarget.appendChild(item)
    })

    this.dropdownTarget.classList.remove("hidden")

    // Add click outside listener
    setTimeout(() => {
      document.addEventListener("click", this.boundClickOutside)
    }, 0)
  }

  hideDropdown() {
    this.dropdownTarget.classList.add("hidden")
    document.removeEventListener("click", this.boundClickOutside)
  }

  selectTitle(event) {
    const title = event.currentTarget.dataset.title
    this.inputTarget.value = title
    this.hideDropdown()
    this.inputTarget.focus()
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideDropdown()
    }
  }

  keydown(event) {
    // Close dropdown on Escape
    if (event.key === "Escape") {
      this.hideDropdown()
      event.preventDefault()
    }
  }
}
