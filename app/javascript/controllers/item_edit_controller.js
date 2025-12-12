import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    itemId: Number,
    title: String,
    listId: Number
  }

  startEditing(e) {
    e.preventDefault()
    e.stopPropagation()

    // Find the item element
    const itemElement = document.getElementById(`item_with_children_${this.itemIdValue}`)
    if (!itemElement) {
      console.error("Item element not found:", `item_with_children_${this.itemIdValue}`)
      return
    }

    // Find the title element (p tag or h3 tag)
    const titleElement = itemElement.querySelector('p:not([class*="text-xs"]), h3')
    if (!titleElement) {
      console.error("Title element not found")
      return
    }

    // Replace the title with an input
    const input = document.createElement('input')
    input.type = 'text'
    input.value = this.titleValue
    input.className = 'flex-1 min-w-0 bg-transparent border-none outline-none text-sm focus:ring-0 px-0'

    // Store original element
    this.originalElement = titleElement
    this.itemElement = itemElement

    // Replace title with input
    titleElement.replaceWith(input)
    input.focus()
    input.select()

    // Handle save on Enter or blur
    input.addEventListener('keydown', (event) => {
      if (event.key === 'Enter') {
        event.preventDefault()
        this.saveEdit(input)
      } else if (event.key === 'Escape') {
        event.preventDefault()
        this.cancelEdit(input)
      }
    })

    input.addEventListener('blur', () => {
      this.saveEdit(input)
    })
  }

  saveEdit(input) {
    const newTitle = input.value.trim()

    if (!newTitle || newTitle === this.titleValue) {
      // No change or empty, just cancel
      this.cancelEdit(input)
      return
    }

    // Show loading state
    if (window.toast) {
      this.loadingToastId = window.toast("Updating item...", {
        type: "loading",
        description: "Please wait"
      })
    }

    // Build form data
    const formData = new FormData()
    formData.append('_method', 'patch')
    formData.append('item[title]', newTitle)
    if (this.hasListIdValue) {
      formData.append('list_id', this.listIdValue)
    }

    // Get CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    // Submit via fetch
    fetch(`/items/${this.itemIdValue}`, {
      method: 'POST',
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-CSRF-Token': csrfToken
      },
      body: formData
    })
    .then(response => response.text())
    .then(html => {
      // Dismiss loading toast
      if (window.toast && window.toast.dismiss && this.loadingToastId) {
        window.toast.dismiss(this.loadingToastId)
        this.loadingToastId = null
      }

      // Let Turbo handle the response
      Turbo.renderStreamMessage(html)
    })
    .catch(error => {
      console.error("Error updating item:", error)

      // Dismiss loading toast and show error
      if (window.toast && window.toast.dismiss && this.loadingToastId) {
        window.toast.dismiss(this.loadingToastId)
        this.loadingToastId = null
      }

      if (window.toast) {
        window.toast("Failed to update item", {
          type: "error"
        })
      }

      this.cancelEdit(input)
    })
  }

  cancelEdit(input) {
    // Restore original element
    if (this.originalElement) {
      input.replaceWith(this.originalElement)
    }
  }
}
