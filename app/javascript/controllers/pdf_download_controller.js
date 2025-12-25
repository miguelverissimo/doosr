import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  download(event) {
    event.preventDefault()
    
    const url = event.currentTarget.href
    const filename = event.currentTarget.download
    
    // Disable button
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = true
    }
    
    // Show loading toast
    const toastId = window.toast && window.toast("Generating PDF...", {
      type: "loading",
      description: "Please wait"
    })
    
    // Download the PDF using fetch
    fetch(url)
      .then(response => {
        if (!response.ok) throw new Error('Download failed')
        return response.blob()
      })
      .then(blob => {
        // Create a download link
        const downloadUrl = window.URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = downloadUrl
        a.download = filename
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        window.URL.revokeObjectURL(downloadUrl)
        
        // Dismiss loading toast
        if (toastId && window.toast) {
          window.toast.dismiss(toastId)
        }
        
        // Show success toast
        if (window.toast) {
          window.toast("PDF downloaded successfully", {
            type: "success"
          })
        }
        
        // Re-enable button
        if (this.hasButtonTarget) {
          this.buttonTarget.disabled = false
        }
      })
      .catch(error => {
        console.error('PDF download error:', error)
        
        // Dismiss loading toast
        if (toastId && window.toast) {
          window.toast.dismiss(toastId)
        }
        
        // Show error toast
        if (window.toast) {
          window.toast("Failed to download PDF", {
            type: "error",
            description: error.message
          })
        }
        
        // Re-enable button
        if (this.hasButtonTarget) {
          this.buttonTarget.disabled = false
        }
      })
  }
}

