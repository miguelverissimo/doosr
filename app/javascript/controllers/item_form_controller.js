import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static targets = [
		"titleInput",
		"itemType",
		"typeIcon",
		"completableButton",
		"sectionButton",
	];
	static values = {
		currentType: { type: String, default: "completable" }, // completable, section, or reusable
		defaultType: { type: String, default: "completable" }, // The default type to reset to
	};

	connect() {
		// Set default type based on initial value
		if (this.hasItemTypeTarget) {
			this.defaultTypeValue = this.itemTypeTarget.value || "completable";
			this.currentTypeValue = this.defaultTypeValue;
		}
		this.updateTypeIcon();
		this.updateButtonStates();
	}

	selectCompletable(e) {
		e.preventDefault();
		this.currentTypeValue = "completable";
		this.itemTypeTarget.value = "completable";
		this.updateButtonStates();
	}

	selectSection(e) {
		e.preventDefault();
		this.currentTypeValue = "section";
		this.itemTypeTarget.value = "section";
		this.updateButtonStates();
	}

	updateButtonStates() {
		// Only update if we have the button targets (for days view)
		if (!this.hasCompletableButtonTarget || !this.hasSectionButtonTarget) {
			return;
		}

		// Remove selected state from both
		this.completableButtonTarget.classList.remove(
			"bg-secondary",
			"text-secondary-foreground",
			"hover:bg-secondary/90",
		);
		this.sectionButtonTarget.classList.remove(
			"bg-secondary",
			"text-secondary-foreground",
			"hover:bg-secondary/90",
		);

		// Add selected state to active button
		if (this.currentTypeValue === "completable") {
			this.completableButtonTarget.classList.add(
				"bg-secondary",
				"text-secondary-foreground",
				"hover:bg-secondary/90",
			);
		} else if (this.currentTypeValue === "section") {
			this.sectionButtonTarget.classList.add(
				"bg-secondary",
				"text-secondary-foreground",
				"hover:bg-secondary/90",
			);
		}
	}

	cycleType(e) {
		e.preventDefault();
		// Toggle between completable and section
		this.currentTypeValue =
			this.currentTypeValue === "completable" ? "section" : "completable";
		this.itemTypeTarget.value = this.currentTypeValue;
		this.updateTypeIcon();
	}

	cycleListType(e) {
		e.preventDefault();
		// Toggle between reusable and section for lists
		this.currentTypeValue =
			this.currentTypeValue === "reusable" ? "section" : "reusable";
		this.itemTypeTarget.value = this.currentTypeValue;
		this.updateTypeIcon();
	}

	updateTypeIcon() {
		// Only update if we have the typeIcon target (for lists view)
		if (!this.hasTypeIconTarget) {
			return;
		}

		const icon = this.typeIconTarget;

		// Clear existing paths
		icon.innerHTML = "";

		if (this.currentTypeValue === "completable") {
			// Completable: circle (checkbox)
			const circle = document.createElementNS(
				"http://www.w3.org/2000/svg",
				"circle",
			);
			circle.setAttribute("cx", "12");
			circle.setAttribute("cy", "12");
			circle.setAttribute("r", "10");
			icon.appendChild(circle);
		} else if (this.currentTypeValue === "reusable") {
			// Reusable: house/home icon
			const path = document.createElementNS(
				"http://www.w3.org/2000/svg",
				"path",
			);
			path.setAttribute("d", "M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z");
			icon.appendChild(path);
		} else {
			// Section: hash symbol
			const line1 = document.createElementNS(
				"http://www.w3.org/2000/svg",
				"line",
			);
			line1.setAttribute("x1", "4");
			line1.setAttribute("x2", "20");
			line1.setAttribute("y1", "9");
			line1.setAttribute("y2", "9");
			icon.appendChild(line1);

			const line2 = document.createElementNS(
				"http://www.w3.org/2000/svg",
				"line",
			);
			line2.setAttribute("x1", "4");
			line2.setAttribute("x2", "20");
			line2.setAttribute("y1", "15");
			line2.setAttribute("y2", "15");
			icon.appendChild(line2);

			const line3 = document.createElementNS(
				"http://www.w3.org/2000/svg",
				"line",
			);
			line3.setAttribute("x1", "10");
			line3.setAttribute("x2", "8");
			line3.setAttribute("y1", "3");
			line3.setAttribute("y2", "21");
			icon.appendChild(line3);

			const line4 = document.createElementNS(
				"http://www.w3.org/2000/svg",
				"line",
			);
			line4.setAttribute("x1", "16");
			line4.setAttribute("x2", "14");
			line4.setAttribute("y1", "3");
			line4.setAttribute("y2", "21");
			icon.appendChild(line4);
		}
	}

	submit(e) {
		// Show loading toast based on item type
		if (window.toast) {
			const itemType = this.currentTypeValue === "section" ? "section" : "item";
			const message =
				this.currentTypeValue === "section"
					? "Creating section..."
					: "Creating item...";

			this.loadingToastId = window.toast(message, {
				type: "loading",
				description: "Please wait",
			});
		}
		// Allow form submission, Turbo will handle it
	}

	clearForm() {
		// Dismiss loading toast if it exists
		if (window.toast && window.toast.dismiss && this.loadingToastId) {
			window.toast.dismiss(this.loadingToastId);
			this.loadingToastId = null;
		}

		// Dispatch event with the title that was just added (before clearing)
		const addedTitle = this.titleInputTarget.value;
		if (addedTitle) {
			this.dispatch("itemAdded", { detail: { title: addedTitle } });
		}

		// Clear the input after successful submission and reset to default type
		this.titleInputTarget.value = "";
		this.currentTypeValue = this.defaultTypeValue;
		this.itemTypeTarget.value = this.defaultTypeValue;
		this.updateTypeIcon();
		this.updateButtonStates();
		this.titleInputTarget.focus();
	}
}
