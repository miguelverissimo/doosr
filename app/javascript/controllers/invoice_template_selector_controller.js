import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static targets = [
		"templateSelect",
		"templateInfo",
		"provider",
		"customer",
		"currency",
		"itemsForm",
		"providerId",
		"customerId",
		"currencyField",
	];
	static values = {
		templates: Array,
	};

	connect() {
		this.templatesData = {};

		if (Array.isArray(this.templatesValue)) {
			this.templatesValue.forEach((template, index) => {
				this.templatesData[String(template.id)] = template;
			});
		} else {
			console.error(
				"[invoice-template-selector] templatesValue is not an array!",
			);
		}
	}

	loadTemplate(event) {
		const templateId = String(event.target.value);

		if (!templateId || templateId === "") {
			// Hide template info when no template selected
			this.templateInfoTarget.classList.add("hidden");
			// Clear hidden fields
			this.providerIdTarget.value = "";
			this.customerIdTarget.value = "";
			this.currencyFieldTarget.value = "";

			// Reset items to one empty item
			if (this.hasItemsFormTarget) {
				const itemsFormController =
					this.application.getControllerForElementAndIdentifier(
						this.itemsFormTarget,
						"invoice-items-form",
					);
				if (itemsFormController) {
					itemsFormController.clearAllItems();
					itemsFormController.addItem();
				}
			}
			return;
		}

		const template = this.templatesData[templateId];
		if (!template) {
			console.error(
				"[invoice-template-selector] Template not found:",
				templateId,
			);
			console.error(
				"[invoice-template-selector] Templates data:",
				this.templatesData,
			);
			return;
		}

		// Update hidden fields
		this.providerIdTarget.value = template.provider_id;
		this.customerIdTarget.value = template.customer_id;
		this.currencyFieldTarget.value = template.currency;

		// Show and populate template info
		this.templateInfoTarget.classList.remove("hidden");
		this.providerTarget.textContent = template.provider_name;
		this.customerTarget.textContent = template.customer_name;
		this.currencyTarget.textContent = template.currency;

		// Update the invoice items form with template items
		if (!this.hasItemsFormTarget) {
			console.error("[invoice-template-selector] Items form target not found");
			console.error(
				"[invoice-template-selector] Available targets:",
				Object.keys(this),
			);
			return;
		}

		const itemsFormController =
			this.application.getControllerForElementAndIdentifier(
				this.itemsFormTarget,
				"invoice-items-form",
			);

		if (!itemsFormController) {
			console.error(
				"[invoice-template-selector] Items form controller not found",
			);
			console.error(
				"[invoice-template-selector] Element:",
				this.itemsFormTarget,
			);
			console.error(
				"[invoice-template-selector] Controllers:",
				this.itemsFormTarget.dataset,
			);
			return;
		}

		// Update currency on the items form controller
		if (template.currency) {
			itemsFormController.currencyValue = template.currency.toLowerCase();
		}

		// Force clear all items
		while (itemsFormController.itemsListTarget.children.length > 0) {
			itemsFormController.itemsListTarget.children[0].remove();
		}

		// Add template items
		if (template.items && template.items.length > 0) {
			template.items.forEach((item) => {
				itemsFormController.addItemWithData(item);
			});
		} else {
			itemsFormController.addItem();
		}

		// Update invoice total after loading template items
		if (itemsFormController.updateInvoiceTotal) {
			itemsFormController.updateInvoiceTotal();
		}
	}
}
