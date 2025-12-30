import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static targets = ["confirmButton", "buttonText"];
	static values = {
		itemId: String,
		dayId: String,
	};

	connect() {
		this.selectedDate = null;

		// Listen for clicks on calendar days directly
		setTimeout(() => {
			const calendar = this.element.querySelector(
				'[data-controller*="ruby-ui--calendar"]',
			);

			if (calendar) {
				// Listen for clicks on day buttons
				calendar.addEventListener("click", (e) => {
					const dayButton = e.target.closest('[data-action*="selectDay"]');
					if (dayButton?.dataset?.day) {
						this.handleDateSelect(dayButton.dataset.day);
					}
				});
			}
		}, 100);
	}

	handleDateSelect(dateString) {
		// Parse and store the date in YYYY-MM-DD format
		const date = new Date(dateString);
		this.selectedDate = date.toISOString().split("T")[0];

		// Update button text and enable it
		const formattedDate = date.toLocaleDateString("en-US", {
			month: "short",
			day: "numeric",
			year: "numeric",
		});

		this.buttonTextTarget.textContent = `Defer to ${formattedDate}`;
		this.confirmButtonTarget.disabled = false;
	}

	confirm() {
		if (!this.selectedDate) {
			return;
		}

		// Disable button and show loading
		this.confirmButtonTarget.disabled = true;
		this.buttonTextTarget.textContent = "Deferring...";

		// Show loading toast
		if (window.toast) {
			this.loadingToastId = window.toast("Deferring item...", {
				type: "loading",
				description: "Please wait",
			});
		}

		// Submit the defer request
		this.submitDefer(this.selectedDate);
	}

	submitDefer(date) {
		const form = document.querySelector("#defer_calendar_form");
		const url = form.action;

		const formData = new FormData();
		formData.append("target_date", date);
		formData.append("_method", "patch");
		if (this.dayIdValue) {
			formData.append("day_id", this.dayIdValue);
		}

		fetch(url, {
			method: "POST",
			headers: {
				"X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
					.content,
				Accept: "text/vnd.turbo-stream.html",
			},
			body: formData,
		})
			.then((response) => {
				return response.text();
			})
			.then((html) => {
				Turbo.renderStreamMessage(html);

				// Dismiss loading toast
				if (window.toast?.dismiss && this.loadingToastId) {
					window.toast.dismiss(this.loadingToastId);
					this.loadingToastId = null;
				}
			})
			.catch(() => {
				// Dismiss loading toast
				if (window.toast?.dismiss && this.loadingToastId) {
					window.toast.dismiss(this.loadingToastId);
					this.loadingToastId = null;
				}

				// Re-enable button on error
				const date = new Date(this.selectedDate);
				const formattedDate = date.toLocaleDateString("en-US", {
					month: "short",
					day: "numeric",
					year: "numeric",
				});
				this.buttonTextTarget.textContent = `Defer to ${formattedDate}`;
				this.confirmButtonTarget.disabled = false;
			});
	}
}
