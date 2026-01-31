import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["source", "button"];
  static values = { successMessage: { type: String, default: "Copied!" } };

  copy() {
    const text = this.sourceTarget.value || this.sourceTarget.textContent;

    navigator.clipboard.writeText(text).then(() => {
      if (window.toast) {
        window.toast(this.successMessageValue, { type: "success" });
      }
    });
  }
}
