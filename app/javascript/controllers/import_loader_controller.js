import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  showLoading(event) {
    console.log("🔄 Import loading started")

    // Show loading toast with spinner/loader
    if (window.toast) {
      console.log("📢 Showing loading toast")
      window.toast("Importing items...", {
        type: "loading",
        description: "Please wait, this may take a few seconds"
      })
    } else {
      console.warn("⚠️ window.toast is not available")
    }
  }
}
