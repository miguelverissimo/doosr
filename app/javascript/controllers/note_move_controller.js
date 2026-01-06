import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static values = {
		noteId: Number,
		dayId: Number,
		listId: Number,
	};

	startMoving(e) {
		e.preventDefault();
		// Store values before closing
		const noteId = this.noteIdValue;
		const dayId = this.hasDayIdValue ? this.dayIdValue : null;
		const listId = this.hasListIdValue ? this.listIdValue : null;

		// Find and click the close button to properly close the sheet
		const closeButton = document.querySelector(
			'#note_actions_sheet [data-action*="sheet-content#close"]',
		);
		if (closeButton) {
			closeButton.click();
		}

		// Wait for sheet to close animation, then enter moving mode
		setTimeout(() => {
			// Dispatch event to notify the page controller
			window.dispatchEvent(
				new CustomEvent("note:start-moving", {
					detail: { noteId, dayId, listId },
				}),
			);
		}, 300);
	}
}
