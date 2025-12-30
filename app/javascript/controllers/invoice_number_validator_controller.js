import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static targets = [
		"numberInput",
		"issueDateInput",
		"errorMessage",
		"submitButton",
	];
	static values = {
		invoiceId: String,
	};

	async validateNumber() {
		const number = this.numberInputTarget.value;
		const issueDateValue = this.issueDateInputTarget.value;

		if (!number || !issueDateValue) {
			this.clearError();
			return;
		}

		// Extract year from issue date
		const issueDate = new Date(issueDateValue);
		const year = issueDate.getFullYear();

		try {
			const url = new URL(
				"/accounting/invoices/check_number",
				window.location.origin,
			);
			url.searchParams.append("number", number);
			url.searchParams.append("year", year);
			if (this.hasInvoiceIdValue && this.invoiceIdValue) {
				url.searchParams.append("invoice_id", this.invoiceIdValue);
			}

			const response = await fetch(url, {
				headers: {
					Accept: "application/json",
					"X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
						.content,
				},
			});

			const data = await response.json();

			if (data.exists) {
				this.showError(data.message);
				this.disableSubmit();
			} else {
				this.clearError();
				this.enableSubmit();
			}
		} catch (error) {
			console.error("[invoice-number-validator] Error checking number:", error);
			this.clearError();
			this.enableSubmit();
		}
	}

	showError(message) {
		if (this.hasErrorMessageTarget) {
			this.errorMessageTarget.textContent = message;
			this.errorMessageTarget.classList.remove("hidden");
			this.numberInputTarget.classList.add("border-red-500");
			this.numberInputTarget.classList.remove("border-border");
		}
	}

	clearError() {
		if (this.hasErrorMessageTarget) {
			this.errorMessageTarget.textContent = "";
			this.errorMessageTarget.classList.add("hidden");
			this.numberInputTarget.classList.remove("border-red-500");
			this.numberInputTarget.classList.add("border-border");
		}
	}

	disableSubmit() {
		if (this.hasSubmitButtonTarget) {
			this.submitButtonTarget.disabled = true;
			this.submitButtonTarget.classList.add("opacity-50", "cursor-not-allowed");
		}
	}

	enableSubmit() {
		if (this.hasSubmitButtonTarget) {
			this.submitButtonTarget.disabled = false;
			this.submitButtonTarget.classList.remove(
				"opacity-50",
				"cursor-not-allowed",
			);
		}
	}
}
