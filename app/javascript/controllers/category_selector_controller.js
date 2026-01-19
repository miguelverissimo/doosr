import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String
  }
  
  static targets = ["select", "badge"]
  
  async change(event) {
    const categoryId = event.target.value
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    
    this.badgeTarget.classList.add("opacity-50")
    
    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": csrfToken
        },
        body: JSON.stringify({
          bank_transaction: {
            category_id: categoryId === "" ? null : categoryId
          }
        })
      })
      
      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)
      }
    } catch (error) {
      console.error("Failed to update category:", error)
      this.badgeTarget.classList.remove("opacity-50")
    }
  }
}
