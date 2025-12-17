import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="migration-settings-form"
export default class extends Controller {
  static targets = ["submitButton", "buttonText"]

  connect() {
    console.log("migration-settings-form controller connected")
    this.pristine = true
    this.storeInitialValues()
    this.updateButtonState()
  }

  storeInitialValues() {
    // Store initial checkbox states
    this.initialValues = {}
    this.element.querySelectorAll('input[type="checkbox"]').forEach(checkbox => {
      this.initialValues[checkbox.name] = checkbox.checked
    })
  }

  checkboxChanged(event) {
    // Mark form as dirty
    this.pristine = false
    this.updateButtonState()
  }

  updateButtonState() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = this.pristine
      if (this.hasButtonTextTarget) {
        this.buttonTextTarget.textContent = this.pristine ? "Settings Saved" : "Save Settings"
      }
    }
  }

  submit(event) {
    console.log("migration-settings-form submit triggered", event)

    // Show loading toast
    const toastId = window.toast && window.toast("Saving migration settings...", {
      type: "loading",
      description: "Please wait"
    })

    // Store the toast ID to dismiss later
    this.toastId = toastId

    // Listen for submission end to dismiss toast and update button state
    const handleSubmitEnd = () => {
      console.log("turbo:submit-end event fired")
      if (this.toastId && window.toast) {
        window.toast.dismiss(this.toastId)
      }

      // Mark as pristine and update button
      this.pristine = true
      this.storeInitialValues()
      this.updateButtonState()

      document.removeEventListener("turbo:submit-end", handleSubmitEnd)
    }

    document.addEventListener("turbo:submit-end", handleSubmitEnd)
  }
}
