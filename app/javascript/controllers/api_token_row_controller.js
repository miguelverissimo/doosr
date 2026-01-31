import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["tokenInput", "revealLabel", "revealButton"];
  static values = { revealed: { type: Boolean, default: false } };

  connect() {
    this.#apply();
  }

  toggleReveal(event) {
    event.preventDefault();
    this.revealedValue = !this.revealedValue;
    this.#apply();
  }

  #apply() {
    if (!this.hasTokenInputTarget) return;

    this.tokenInputTarget.type = this.revealedValue ? "text" : "password";

    if (this.hasRevealLabelTarget) {
      this.revealLabelTarget.textContent = this.revealedValue ? "Hide" : "Reveal";
    }

    if (this.hasRevealButtonTarget) {
      this.revealButtonTarget.setAttribute("aria-pressed", String(this.revealedValue));
    }
  }
}

