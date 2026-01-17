import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	connect() {
		this.highlightFromUrl();
	}

	highlightFromUrl() {
		const url = new URL(window.location.href);
		const highlightId = url.searchParams.get("highlight");

		if (!highlightId) {
			return;
		}

		const itemElement = document.getElementById(`item_${highlightId}`);

		if (itemElement) {
			// Scroll the item into view with smooth behavior
			itemElement.scrollIntoView({ behavior: "smooth", block: "center" });

			// Apply highlight animation after a small delay to ensure scroll completes
			setTimeout(() => {
				itemElement.classList.add("item-highlight-flash");

				// Remove the animation class after it completes
				setTimeout(() => {
					itemElement.classList.remove("item-highlight-flash");
				}, 1500);
			}, 300);
		}

		// Remove the highlight param from URL without triggering navigation
		url.searchParams.delete("highlight");
		window.history.replaceState({}, "", url.toString());
	}
}
