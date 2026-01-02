import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  close(event) {
    event.preventDefault()

    // Find the parent dialog controller and call dismiss
    const dialogElement = this.element.closest('[data-controller*="ruby-ui--dialog"]')
    if (dialogElement) {
      const dialogController = this.application.getControllerForElementAndIdentifier(
        dialogElement,
        "ruby-ui--dialog"
      )
      if (dialogController) {
        dialogController.dismiss()
        return
      }
    }
    
    // If not a ruby-ui dialog, find the closest dialog container and remove it
    // along with any sibling backdrop
    const dialogContainer = this.element.closest('[role="dialog"]')
    if (dialogContainer) {
      // Find the parent wrapper (which contains both backdrop and dialog)
      const wrapper = dialogContainer.parentElement
      if (wrapper && wrapper.parentElement && wrapper.parentElement.id === 'ritual_modal_container') {
        // Clear the entire modal container
        wrapper.parentElement.innerHTML = ''
      } else {
        // Fallback: remove just the dialog and backdrop
        const backdrop = dialogContainer.previousElementSibling
        if (backdrop && backdrop.classList.contains('fixed') && backdrop.classList.contains('inset-0')) {
          backdrop.remove()
        }
        dialogContainer.remove()
      }
      // Re-enable body scroll
      document.body.classList.remove('overflow-hidden')
    }
  }
}
