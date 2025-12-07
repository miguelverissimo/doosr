import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  showLoading() {
    const submitButton = this.element.querySelector('button[type="submit"]')
    if (submitButton) {
      submitButton.disabled = true
      submitButton.dataset.originalText = submitButton.textContent

      // Determine loading text based on button text
      const loadingText = submitButton.textContent.includes("Create")
        ? "Creating account..."
        : "Signing in..."

      submitButton.textContent = loadingText
    }
  }

  hideLoading() {
    const submitButton = this.element.querySelector('button[type="submit"]')
    if (submitButton) {
      submitButton.disabled = false
      if (submitButton.dataset.originalText) {
        submitButton.textContent = submitButton.dataset.originalText
      }
    }
  }

  clearError() {
    const errorContainer = document.getElementById('auth_error')
    if (errorContainer) {
      errorContainer.innerHTML = ''
    }
  }
}
