import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  updatePreview() {
    const input = this.element;
    const preview = document.getElementById("color_preview");
    const value = input.value;

    // Only update if it's a valid hex color
    if (/^#[0-9A-Fa-f]{6}$/.test(value)) {
      preview.style.backgroundColor = value;
    }
  }

  selectColor(event) {
    const color = event.params.color;
    const input = document.getElementById("category_color");
    const preview = document.getElementById("color_preview");

    input.value = color;
    preview.style.backgroundColor = color;

    // Update button borders to show selection
    const buttons = event.currentTarget.parentElement.querySelectorAll("button");
    buttons.forEach((btn) => {
      const btnColor = btn.dataset.colorInputColorParam;
      btn.style.borderColor = btnColor === color ? "currentColor" : "transparent";
    });
  }
}
