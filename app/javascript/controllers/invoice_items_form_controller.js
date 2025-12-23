import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static targets = ["itemsContainer", "itemsList"];
	static values = {
		accountingItems: { type: Object, default: {} },
		taxBrackets: { type: Object, default: {} },
		currency: { type: String, default: "EUR" },
		initialItems: { type: Array, default: [] },
		formPrefix: { type: String, default: "invoice[invoice_items_attributes]" },
	};

	connect() {
		// If we have initial items (e.g. editing an existing invoice), render those.
		if (
			this.initialItemsValue.length > 0 &&
			this.itemsListTarget.children.length === 0
		) {
			this.initialItemsValue.forEach((item) => this.addItemWithData(item));
		} else if (this.itemsListTarget.children.length === 0) {
			// Otherwise ensure at least one empty item exists
			this.addItem();
		}
	}

	addItem() {
		const index = this.itemsListTarget.children.length;
		const itemRow = this.createItemRow(index);
		this.itemsListTarget.appendChild(itemRow);
		this.updateCalculations(index);
	}

	addItemWithData(data) {
		const index = this.itemsListTarget.children.length;
		const row = this.createItemRow(index);
		this.itemsListTarget.appendChild(row);

		// Populate fields from provided data
		const itemSelect = row.querySelector('select[name*="[item_id]"]');
		if (itemSelect && data.item_id) {
			itemSelect.value = String(data.item_id);
		}

		const quantityInput = row.querySelector('input[name*="[quantity]"]');
		if (quantityInput && data.quantity != null) {
			quantityInput.value = data.quantity;
		}

		const discountRateInput = row.querySelector(
			'input[name*="[discount_rate]"]',
		);
		if (discountRateInput && data.discount_rate != null) {
			discountRateInput.value = data.discount_rate;
		}

		const taxBracketSelect = row.querySelector(
			'select[name*="[tax_bracket_id]"]',
		);
		if (taxBracketSelect && data.tax_bracket_id) {
			taxBracketSelect.value = String(data.tax_bracket_id);
		}

		const descriptionField = row.querySelector('input[name*="[description]"]');
		if (descriptionField && data.description != null) {
			descriptionField.value = data.description;
		}

		const unitField = row.querySelector('input[name*="[unit]"]');
		if (unitField && data.unit != null) {
			unitField.value = data.unit;
		}

		// Run calculations to fill in the monetary fields & displays
		this.updateCalculations(index);
	}

	removeItem(event) {
		const row = event.currentTarget.closest(
			'[data-invoice-items-form-target="itemRow"]',
		);
		if (row) {
			row.remove();
			// Re-index all remaining items
			this.reindexItems();
			// Ensure at least one item remains
			if (this.itemsListTarget.children.length === 0) {
				this.addItem();
			}
		}
	}

	reindexItems() {
		Array.from(this.itemsListTarget.children).forEach((row, index) => {
			// Update all input names with new index
			// Support both invoice_items_attributes and invoice_template_items_attributes
			row.querySelectorAll("input, select").forEach((input) => {
				if (input.name) {
					input.name = input.name.replace(
						/\[(invoice_items_attributes|invoice_template_items_attributes)\]\[\d+\]/,
						`[$1][${index}]`,
					);
				}
			});
		});
	}

	updateItem(event) {
		const row = event.currentTarget.closest(
			'[data-invoice-items-form-target="itemRow"]',
		);
		const index = Array.from(this.itemsListTarget.children).indexOf(row);
		this.updateCalculations(index);
	}

	updateCalculations(index) {
		const row = this.itemsListTarget.children[index];
		if (!row) return;

		const formPrefix = this.formPrefixValue || "invoice[invoice_items_attributes]";
		const isTemplateForm = formPrefix.includes("invoice_template_items_attributes");

		const accountingItemId = row.querySelector('[name*="[item_id]"]')?.value;
		const quantityInput = row.querySelector('[name*="[quantity]"]');
		const discountRateInput = row.querySelector('[name*="[discount_rate]"]');
		const taxBracketId = row.querySelector('[name*="[tax_bracket_id]"]')?.value;

		if (
			!accountingItemId ||
			!quantityInput ||
			!discountRateInput ||
			!taxBracketId
		) {
			return;
		}

		const accountingItem = this.accountingItemsValue[accountingItemId];
		if (!accountingItem) return;

		const quantity = parseFloat(quantityInput.value) || 0;
		const discountRate = parseFloat(discountRateInput.value) || 0;
		const taxBracket = this.taxBracketsValue[taxBracketId];
		if (!taxBracket) return;

		const unitPrice = accountingItem.price || 0;
		const taxRate = taxBracket.percentage || 0;

		// Calculate fields
		const subtotal = quantity * unitPrice;
		const discountAmount = subtotal * (discountRate / 100);
		const taxAmount = (subtotal - discountAmount) * (taxRate / 100);
		const amount = subtotal - discountAmount + taxAmount;

		// Update hidden fields
		const descriptionField = row.querySelector('[name*="[description]"]');
		const unitField = row.querySelector('[name*="[unit]"]');

		if (descriptionField && !descriptionField.value)
			descriptionField.value = accountingItem.name || "";
		if (unitField && !unitField.value)
			unitField.value = accountingItem.unit || "";

		// Only update monetary fields for invoice forms, not template forms
		if (!isTemplateForm) {
			const unitPriceField = row.querySelector('[name*="[unit_price]"]');
			const subtotalField = row.querySelector('[name*="[subtotal]"]');
			const discountAmountField = row.querySelector(
				'[name*="[discount_amount]"]',
			);
			const taxRateField = row.querySelector('[name*="[tax_rate]"]');
			const taxAmountField = row.querySelector('[name*="[tax_amount]"]');
			const amountField = row.querySelector('[name*="[amount]"]');

			if (unitPriceField) unitPriceField.value = Math.round(unitPrice * 100); // Convert to cents
			if (subtotalField) subtotalField.value = Math.round(subtotal * 100); // Convert to cents
			if (discountAmountField)
				discountAmountField.value = Math.round(discountAmount * 100); // Convert to cents
			if (taxRateField) taxRateField.value = taxRate;
			if (taxAmountField) taxAmountField.value = Math.round(taxAmount * 100); // Convert to cents
			if (amountField) amountField.value = Math.round(amount * 100); // Convert to cents

			// Update displayed values
			const subtotalDisplay = row.querySelector(
				'[data-invoice-items-form-target="subtotalDisplay"]',
			);
			const discountAmountDisplay = row.querySelector(
				'[data-invoice-items-form-target="discountAmountDisplay"]',
			);
			const taxAmountDisplay = row.querySelector(
				'[data-invoice-items-form-target="taxAmountDisplay"]',
			);
			const amountDisplay = row.querySelector(
				'[data-invoice-items-form-target="amountDisplay"]',
			);

			if (subtotalDisplay)
				subtotalDisplay.textContent = this.formatCurrency(subtotal);
			if (discountAmountDisplay)
				discountAmountDisplay.textContent = this.formatCurrency(discountAmount);
			if (taxAmountDisplay)
				taxAmountDisplay.textContent = this.formatCurrency(taxAmount);
			if (amountDisplay) amountDisplay.textContent = this.formatCurrency(amount);
		}
	}

	formatCurrency(value) {
		return new Intl.NumberFormat("en-US", {
			style: "currency",
			currency: this.currencyValue || "EUR",
			minimumFractionDigits: 2,
			maximumFractionDigits: 2,
		}).format(value);
	}

	createItemRow(index) {
		const formPrefix = this.formPrefixValue || "invoice[invoice_items_attributes]";
		const isTemplateForm = formPrefix.includes("invoice_template_items_attributes");
		
		const row = document.createElement("div");
		row.className = "space-y-4 p-4 border rounded-md bg-background";
		row.dataset.invoiceItemsFormTarget = "itemRow";

		// Accounting Item Select
		const accountingItemField = document.createElement("div");
		accountingItemField.className = "space-y-2";
		accountingItemField.innerHTML = `
      <label class="text-sm font-medium">Accounting Item</label>
      <select 
        name="${formPrefix}[${index}][item_id]" 
        class="flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
        required
        data-action="change->invoice-items-form#updateItem"
      >
        <option value="">Select an item</option>
        ${Object.entries(this.accountingItemsValue)
					.map(
						([id, item]) =>
							`<option value="${id}">${item.name} (${item.reference})</option>`,
					)
					.join("")}
      </select>
    `;
		row.appendChild(accountingItemField);

		// Quantity and Discount Rate in a row
		const quantityDiscountRow = document.createElement("div");
		quantityDiscountRow.className = "grid grid-cols-2 gap-4";

		const quantityField = document.createElement("div");
		quantityField.className = "space-y-2";
		quantityField.innerHTML = `
      <label class="text-sm font-medium">Quantity</label>
      <input 
        type="number" 
        name="${formPrefix}[${index}][quantity]" 
        step="0.01" 
        min="0"
        value="1"
        class="flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
        required
        data-action="input->invoice-items-form#updateItem"
      />
    `;
		quantityDiscountRow.appendChild(quantityField);

		const discountRateField = document.createElement("div");
		discountRateField.className = "space-y-2";
		discountRateField.innerHTML = `
      <label class="text-sm font-medium">Discount Rate (%)</label>
      <input 
        type="number" 
        name="${formPrefix}[${index}][discount_rate]" 
        step="0.01" 
        min="0" 
        max="100"
        value="0"
        class="flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
        required
        data-action="input->invoice-items-form#updateItem"
      />
    `;
		quantityDiscountRow.appendChild(discountRateField);
		row.appendChild(quantityDiscountRow);

		// Tax Bracket Select
		const taxBracketField = document.createElement("div");
		taxBracketField.className = "space-y-2";
		taxBracketField.innerHTML = `
      <label class="text-sm font-medium">Tax Bracket</label>
      <select 
        name="${formPrefix}[${index}][tax_bracket_id]" 
        class="flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
        required
        data-action="change->invoice-items-form#updateItem"
      >
        <option value="">Select a tax bracket</option>
        ${Object.entries(this.taxBracketsValue)
					.map(
						([id, bracket]) =>
							`<option value="${id}">${bracket.name} (${bracket.percentage}%)</option>`,
					)
					.join("")}
      </select>
    `;
		row.appendChild(taxBracketField);

		// Calculated values display (only for invoice forms, not template forms)
		if (!isTemplateForm) {
			const calculatedValues = document.createElement("div");
			calculatedValues.className = "grid grid-cols-2 gap-4 text-sm";
			const zeroFormatted = this.formatCurrency(0);
			calculatedValues.innerHTML = `
        <div>
          <span class="text-muted-foreground">Subtotal:</span>
          <span class="ml-2 font-medium" data-invoice-items-form-target="subtotalDisplay">${zeroFormatted}</span>
        </div>
        <div>
          <span class="text-muted-foreground">Discount:</span>
          <span class="ml-2 font-medium" data-invoice-items-form-target="discountAmountDisplay">${zeroFormatted}</span>
        </div>
        <div>
          <span class="text-muted-foreground">Tax:</span>
          <span class="ml-2 font-medium" data-invoice-items-form-target="taxAmountDisplay">${zeroFormatted}</span>
        </div>
        <div>
          <span class="text-muted-foreground">Total:</span>
          <span class="ml-2 font-semibold" data-invoice-items-form-target="amountDisplay">${zeroFormatted}</span>
        </div>
      `;
			row.appendChild(calculatedValues);
		}

		// Hidden fields
		const hiddenFields = document.createElement("div");
		hiddenFields.style.display = "none";
		if (isTemplateForm) {
			// Template form only needs description and unit (no monetary fields)
			hiddenFields.innerHTML = `
        <input type="hidden" name="${formPrefix}[${index}][description]" />
        <input type="hidden" name="${formPrefix}[${index}][unit]" />
      `;
		} else {
			// Invoice form needs all fields including monetary ones
			hiddenFields.innerHTML = `
        <input type="hidden" name="${formPrefix}[${index}][description]" />
        <input type="hidden" name="${formPrefix}[${index}][unit]" />
        <input type="hidden" name="${formPrefix}[${index}][unit_price]" />
        <input type="hidden" name="${formPrefix}[${index}][subtotal]" />
        <input type="hidden" name="${formPrefix}[${index}][discount_amount]" />
        <input type="hidden" name="${formPrefix}[${index}][tax_rate]" />
        <input type="hidden" name="${formPrefix}[${index}][tax_amount]" />
        <input type="hidden" name="${formPrefix}[${index}][amount]" />
      `;
		}
		row.appendChild(hiddenFields);

		// Remove button
		const removeButton = document.createElement("button");
		removeButton.type = "button";
		removeButton.className =
			"text-sm text-destructive hover:text-destructive/80 mt-2";
		removeButton.dataset.action = "click->invoice-items-form#removeItem";
		removeButton.textContent = "Remove Item";
		row.appendChild(removeButton);

		return row;
	}
}
