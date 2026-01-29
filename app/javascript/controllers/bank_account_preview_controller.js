import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["badge"]

  update() {
    const letter = document.getElementById("bank_account_letter")?.value || "M"
    const bgColor = document.getElementById("bank_account_bg_color")?.value || "#3B82F6"
    const fgColor = document.getElementById("bank_account_fg_color")?.value || "#FFFFFF"

    if (this.hasBadgeTarget) {
      this.badgeTarget.textContent = letter.substring(0, 2).toUpperCase() || "M"
      this.badgeTarget.style.backgroundColor = bgColor
      this.badgeTarget.style.color = fgColor
    }
  }
}
