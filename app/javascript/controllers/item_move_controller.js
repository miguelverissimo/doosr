import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static values = {
		itemId: Number,
		dayId: Number,
	};

	static targets = ["cancelButton"];

	startMoving(e) {
		e.preventDefault();
		// Store values before closing
		const itemId = this.itemIdValue;
		const dayId = this.dayIdValue;

		// Find and click the close button to properly close the sheet
		const closeButton = document.querySelector(
			'#actions_sheet [data-action*="sheet-content#close"]',
		);
		if (closeButton) {
			closeButton.click();
		}

		// Wait for sheet to close animation, then enter moving mode
		setTimeout(() => {
			// Dispatch event to notify the page controller
			window.dispatchEvent(
				new CustomEvent("item:start-moving", {
					detail: { itemId, dayId },
				}),
			);
		}, 300);
	}
}
