import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static targets = [
		"itemsContainer",
		"itemsList",
		"itemsInput",
		"itemRow",
		"itemTitle",
	];

	connect() {
		this.items = this.loadItems();
		// If we have existing item rows, don't re-render (they're already in the DOM)
		// Otherwise, render the items
		if (this.items.length > 0 && this.itemRowTargets.length === 0) {
			this.renderItems();
		} else {
			this.updateHiddenInput();
		}
	}

	loadItems() {
		const input = this.itemsInputTarget;
		if (input.value) {
			try {
				return JSON.parse(input.value);
			} catch (e) {
				console.error("Failed to parse items:", e);
				return [];
			}
		}
		// If no value, load from existing item rows
		const items = [];
		this.itemRowTargets.forEach((row, _index) => {
			const titleInput = row.querySelector(
				'[data-checklist-form-target="itemTitle"]',
			);
			if (titleInput) {
				items.push({
					type: "completable",
					title: titleInput.value || "",
					completed_at: null,
				});
			}
		});
		return items;
	}

	updateHiddenInput() {
		this.itemsInputTarget.value = JSON.stringify(this.items);
	}

	addItem() {
		this.items.push({
			type: "completable",
			title: "",
			completed_at: null,
		});
		this.renderItems();
		// Focus on the new item's input
		setTimeout(() => {
			const newRow = this.itemRowTargets[this.itemRowTargets.length - 1];
			const newInput = newRow?.querySelector(
				'[data-checklist-form-target="itemTitle"]',
			);
			if (newInput) {
				newInput.focus();
			}
		}, 0);
	}

	removeItem(event) {
		const index = parseInt(event.currentTarget.dataset.itemIndex);
		this.items.splice(index, 1);
		this.renderItems();
	}

	updateItem(event) {
		const index = parseInt(event.currentTarget.dataset.itemIndex);
		const title = event.currentTarget.value;
		if (this.items[index]) {
			this.items[index].title = title;
			this.updateHiddenInput();
		}
	}

	moveUp(event) {
		const index = parseInt(event.currentTarget.dataset.itemIndex);
		if (index > 0) {
			[this.items[index - 1], this.items[index]] = [
				this.items[index],
				this.items[index - 1],
			];
			this.renderItems();
			// Update button states
			this.updateButtonStates();
		}
	}

	moveDown(event) {
		const index = parseInt(event.currentTarget.dataset.itemIndex);
		if (index < this.items.length - 1) {
			[this.items[index], this.items[index + 1]] = [
				this.items[index + 1],
				this.items[index],
			];
			this.renderItems();
			// Update button states
			this.updateButtonStates();
		}
	}

	updateButtonStates() {
		this.itemRowTargets.forEach((row, index) => {
			const moveUpBtn = row.querySelector('[data-action*="moveUp"]');
			const moveDownBtn = row.querySelector('[data-action*="moveDown"]');
			if (moveUpBtn) {
				moveUpBtn.disabled = index === 0;
			}
			if (moveDownBtn) {
				moveDownBtn.disabled = index === this.items.length - 1;
			}
		});
	}

	startDrag(event) {
		// Simple drag implementation - could be enhanced with drag-and-drop API
		event.preventDefault();
		const _index = parseInt(event.currentTarget.dataset.itemIndex);
		// For now, we'll use move up/down buttons instead of drag
		// This can be enhanced later with proper drag-and-drop
	}

	renderItems() {
		// Clear existing items
		this.itemsListTarget.innerHTML = "";

		// Re-render all items
		this.items.forEach((item, index) => {
			const row = this.createItemRow(item, index);
			this.itemsListTarget.appendChild(row);
		});

		// Update button states
		this.updateButtonStates();
		this.updateHiddenInput();
	}

	createItemRow(item, index) {
		const row = document.createElement("div");
		row.className =
			"flex items-center gap-2 p-2 border rounded-md bg-background";
		row.dataset.checklistFormTarget = "itemRow";
		row.dataset.itemIndex = index;

		// Drag handle
		const dragHandle = document.createElement("button");
		dragHandle.type = "button";
		dragHandle.className =
			"cursor-move text-muted-foreground hover:text-foreground";
		dragHandle.dataset.action = "mousedown->checklist-form#startDrag";
		dragHandle.dataset.itemIndex = index;
		dragHandle.title = "Drag to reorder";
		dragHandle.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <circle cx="9" cy="12" r="1"></circle>
        <circle cx="9" cy="5" r="1"></circle>
        <circle cx="9" cy="19" r="1"></circle>
        <circle cx="15" cy="12" r="1"></circle>
        <circle cx="15" cy="5" r="1"></circle>
        <circle cx="15" cy="19" r="1"></circle>
      </svg>
    `;
		row.appendChild(dragHandle);

		// Title input
		const titleInput = document.createElement("input");
		titleInput.type = "text";
		titleInput.className =
			"flex h-9 w-full rounded-md border bg-background px-3 py-1 text-sm shadow-sm transition-colors border-border placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring flex-1";
		titleInput.placeholder = "Enter item title";
		titleInput.value = item.title || "";
		titleInput.dataset.checklistFormTarget = "itemTitle";
		titleInput.dataset.itemIndex = index;
		titleInput.dataset.action = "input->checklist-form#updateItem";
		row.appendChild(titleInput);

		// Move up button
		const moveUpBtn = document.createElement("button");
		moveUpBtn.type = "button";
		moveUpBtn.className =
			"text-muted-foreground hover:text-foreground disabled:opacity-50 disabled:cursor-not-allowed";
		moveUpBtn.dataset.action = "click->checklist-form#moveUp";
		moveUpBtn.dataset.itemIndex = index;
		moveUpBtn.title = "Move up";
		if (index === 0) {
			moveUpBtn.disabled = true;
		}
		moveUpBtn.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="18 15 12 9 6 15"></polyline>
      </svg>
    `;
		row.appendChild(moveUpBtn);

		// Move down button
		const moveDownBtn = document.createElement("button");
		moveDownBtn.type = "button";
		moveDownBtn.className =
			"text-muted-foreground hover:text-foreground disabled:opacity-50 disabled:cursor-not-allowed";
		moveDownBtn.dataset.action = "click->checklist-form#moveDown";
		moveDownBtn.dataset.itemIndex = index;
		moveDownBtn.title = "Move down";
		if (index === this.items.length - 1) {
			moveDownBtn.disabled = true;
		}
		moveDownBtn.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <polyline points="6 9 12 15 18 9"></polyline>
      </svg>
    `;
		row.appendChild(moveDownBtn);

		// Remove button
		const removeBtn = document.createElement("button");
		removeBtn.type = "button";
		removeBtn.className =
			"px-3 py-1.5 h-8 text-xs whitespace-nowrap inline-flex items-center justify-center rounded-md font-medium transition-colors disabled:pointer-events-none disabled:opacity-50 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring aria-disabled:pointer-events-none aria-disabled:opacity-50 aria-disabled:cursor-not-allowe bg-destructive text-white shadow-sm [a&]:hover:bg-destructive/90 focus-visible:ring-destructive/20 dark:focus-visible:ring-destructive/40 dark:bg-destructive/60";
		removeBtn.dataset.action = "click->checklist-form#removeItem";
		removeBtn.dataset.itemIndex = index;
		removeBtn.title = "Remove item";
		removeBtn.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <line x1="18" y1="6" x2="6" y2="18"></line>
        <line x1="6" y1="6" x2="18" y2="18"></line>
      </svg>
    `;
		row.appendChild(removeBtn);

		return row;
	}
}
