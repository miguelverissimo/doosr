import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static targets = ["item", "cancelButton", "rootTarget"];
	static values = { dayId: Number, listId: Number };

	connect() {
		// Check if we're returning from a moving mode
		const movingItemId = sessionStorage.getItem("movingItemId");
		const movingRecordType = sessionStorage.getItem("movingRecordType") || "Item";
		if (movingItemId) {
			this.enterMovingMode(parseInt(movingItemId), movingRecordType);
		}

		// Listen for moving mode events
		this.boundStartMoving = this.handleStartMoving.bind(this);
		this.boundStartMovingNote = this.handleStartMovingNote.bind(this);
		this.boundCancelMoving = this.handleCancelMoving.bind(this);
		this.boundEscapeKey = this.handleEscapeKey.bind(this);

		window.addEventListener("item:start-moving", this.boundStartMoving);
		window.addEventListener("note:start-moving", this.boundStartMovingNote);
		window.addEventListener("item:cancel-moving", this.boundCancelMoving);
		document.addEventListener("keydown", this.boundEscapeKey);
	}

	disconnect() {
		window.removeEventListener("item:start-moving", this.boundStartMoving);
		window.removeEventListener("note:start-moving", this.boundStartMovingNote);
		window.removeEventListener("item:cancel-moving", this.boundCancelMoving);
		document.removeEventListener("keydown", this.boundEscapeKey);
	}

	handleStartMoving(event) {
		this.enterMovingMode(event.detail.itemId, "Item");
	}

	handleStartMovingNote(event) {
		this.enterMovingMode(event.detail.noteId, "Note");
	}

	handleCancelMoving(event) {
		this.exitMovingMode();

		// Reopen the drawer on the original item
		const itemElement = document.getElementById(`item_${event.detail.itemId}`);
		if (itemElement) {
			setTimeout(() => {
				itemElement.click();
			}, 100);
		}
	}

	handleEscapeKey(event) {
		if (event.key === "Escape" && this.isInMovingMode()) {
			event.preventDefault();
			this.cancelMoving();
		}
	}

	enterMovingMode(recordId, recordType = "Item") {
		this.movingItemId = recordId;
		this.movingRecordType = recordType;

		// Store in sessionStorage for persistence
		sessionStorage.setItem("movingItemId", recordId);
		sessionStorage.setItem("movingRecordType", recordType);
		if (this.hasDayIdValue) {
			sessionStorage.setItem("movingDayId", this.dayIdValue);
		}
		if (this.hasListIdValue) {
			sessionStorage.setItem("movingListId", this.listIdValue);
		}

		// Show cancel button
		if (this.hasCancelButtonTarget) {
			this.cancelButtonTarget.classList.remove("hidden");
		}

		// Check if record is at root level (direct child of items_list)
		const elementId = recordType === "Note" ? `note_${recordId}` : `item_${recordId}`;
		const recordElement = document.getElementById(elementId);
		const isAtRootLevel =
			recordElement && recordElement.parentElement.id === "items_list";

		// Only show root target if record is NOT already at root level
		if (this.hasRootTargetTarget && !isAtRootLevel) {
			this.rootTargetTarget.classList.remove("hidden");
		}

		// Highlight the moving record
		if (recordElement) {
			recordElement.classList.add("bg-pink-500/20", "border-pink-500");
		}

		// Highlight all other items as targets
		this.itemTargets.forEach((item) => {
			const currentItemId = parseInt(
				item.dataset.itemMovingItemIdValue || item.dataset.itemIdValue,
			);
			if (currentItemId !== recordId) {
				item.classList.add(
					"border-2",
					"border-dashed",
					"border-primary",
					"cursor-pointer",
				);
				// Replace the action with selectTarget during moving mode
				item.dataset.action = "click->day-move#selectTarget";
				item.dataset.dayMoveTargetItemId = currentItemId;
			}
		});
	}

	exitMovingMode() {
		// Hide cancel button
		if (this.hasCancelButtonTarget) {
			this.cancelButtonTarget.classList.add("hidden");
		}

		// Hide root target (always, since it might have been shown)
		if (this.hasRootTargetTarget) {
			this.rootTargetTarget.classList.add("hidden");
		}

		// Remove highlights from moving record
		if (this.movingItemId) {
			const elementId = this.movingRecordType === "Note" ? `note_${this.movingItemId}` : `item_${this.movingItemId}`;
			const recordElement = document.getElementById(elementId);
			if (recordElement) {
				recordElement.classList.remove("bg-pink-500/20", "border-pink-500");
			}
		}

		// Remove highlights from all target items
		this.itemTargets.forEach((item) => {
			item.classList.remove(
				"border-2",
				"border-dashed",
				"border-primary",
				"cursor-pointer",
			);
			// Remove the dynamic action we added (keep original actions)
			const originalAction = "click->item#openSheet";
			item.dataset.action = originalAction;
			delete item.dataset.dayMoveTargetItemId;
		});

		// Clear session storage
		sessionStorage.removeItem("movingItemId");
		sessionStorage.removeItem("movingRecordType");
		sessionStorage.removeItem("movingDayId");
		sessionStorage.removeItem("movingListId");

		this.movingItemId = null;
		this.movingRecordType = null;
	}

	isInMovingMode() {
		return this.movingItemId != null;
	}

	cancelMoving() {
		const movingItemId = this.movingItemId;

		// Exit moving mode (clears sessionStorage and resets UI)
		this.exitMovingMode();

		// Reopen the drawer on the original item
		if (movingItemId) {
			const itemElement = document.getElementById(`item_${movingItemId}`);
			if (itemElement) {
				setTimeout(() => {
					itemElement.click();
				}, 100);
			}
		}
	}

	selectTarget(event) {
		if (!this.isInMovingMode()) return;

		event.stopPropagation();
		event.preventDefault();

		const targetItemId = parseInt(
			event.currentTarget.dataset.dayMoveTargetItemId,
		);

		this.moveItemToTarget(this.movingItemId, targetItemId);
	}

	selectRootTarget(event) {
		if (!this.isInMovingMode()) {
			return;
		}

		event.stopPropagation();
		event.preventDefault();

		this.moveItemToRoot(this.movingItemId);
	}

	moveItemToTarget(itemId, targetItemId) {
		const recordType = this.movingRecordType || "Item";
		const recordLabel = recordType === "Note" ? "note" : "item";

		// Show loading toast
		let loadingToastId = null;
		if (window.toast) {
			loadingToastId = window.toast(`Reparenting ${recordLabel}...`, {
				type: "loading",
				description: "Please wait",
			});
		}

		// Exit moving mode first
		this.exitMovingMode();

		// Clear session storage
		sessionStorage.removeItem("movingItemId");
		sessionStorage.removeItem("movingRecordType");
		sessionStorage.removeItem("movingDayId");
		sessionStorage.removeItem("movingListId");

		// Build request body based on context (day or list)
		const requestBody = {
			target_item_id: targetItemId,
		};
		if (this.hasDayIdValue) {
			requestBody.day_id = this.dayIdValue;
		} else if (this.hasListIdValue) {
			requestBody.list_id = this.listIdValue;
		}

		// Make the reparent request
		// Determine URL based on record type and context
		let reparentUrl;
		if (recordType === "Note") {
			reparentUrl = `/notes/${itemId}/reparent`;
		} else {
			// Use reusable_items path if we have a list_id, otherwise use items path
			reparentUrl = this.hasListIdValue
				? `/reusable_items/${itemId}/reparent`
				: `/items/${itemId}/reparent`;
		}
		fetch(reparentUrl, {
			method: "PATCH",
			headers: {
				"Content-Type": "application/json",
				Accept: "text/vnd.turbo-stream.html",
				"X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
					.content,
			},
			body: JSON.stringify(requestBody),
		})
			.then((response) => response.text())
			.then((html) => {
				// Dismiss loading toast
				if (loadingToastId && window.toast && window.toast.dismiss) {
					window.toast.dismiss(loadingToastId);
				}

				// Process turbo stream response
				Turbo.renderStreamMessage(html);

				// Reopen drawer on moved record after DOM updates
				setTimeout(() => {
					const elementId = recordType === "Note" ? `note_${itemId}` : `item_${itemId}`;
					const movedElement = document.getElementById(elementId);
					if (movedElement) {
						movedElement.click();
					}
				}, 300);
			})
			.catch((error) => {
				console.error("Error moving item:", error);

				// Dismiss loading toast on error
				if (loadingToastId && window.toast && window.toast.dismiss) {
					window.toast.dismiss(loadingToastId);
				}

				// Show error toast
				if (window.toast) {
					window.toast("Failed to move item", {
						type: "error",
						description: error.message,
					});
				}
			});
	}

	moveItemToRoot(itemId) {
		const recordType = this.movingRecordType || "Item";
		const recordLabel = recordType === "Note" ? "note" : "item";

		// Show loading toast
		let loadingToastId = null;
		if (window.toast) {
			loadingToastId = window.toast(`Reparenting ${recordLabel}...`, {
				type: "loading",
				description: "Please wait",
			});
		}

		// Exit moving mode first
		this.exitMovingMode();

		// Clear session storage
		sessionStorage.removeItem("movingItemId");
		sessionStorage.removeItem("movingRecordType");
		sessionStorage.removeItem("movingDayId");
		sessionStorage.removeItem("movingListId");

		// Build request body based on context (day or list)
		const requestBody = {
			target_item_id: null,
		};
		if (this.hasDayIdValue) {
			requestBody.day_id = this.dayIdValue;
		} else if (this.hasListIdValue) {
			requestBody.list_id = this.listIdValue;
		}

		// Make the reparent request
		// Determine URL based on record type and context
		let reparentUrl;
		if (recordType === "Note") {
			reparentUrl = `/notes/${itemId}/reparent`;
		} else {
			// Use reusable_items path if we have a list_id, otherwise use items path
			reparentUrl = this.hasListIdValue
				? `/reusable_items/${itemId}/reparent`
				: `/items/${itemId}/reparent`;
		}
		fetch(reparentUrl, {
			method: "PATCH",
			headers: {
				"Content-Type": "application/json",
				Accept: "text/vnd.turbo-stream.html",
				"X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
					.content,
			},
			body: JSON.stringify(requestBody),
		})
			.then((response) => response.text())
			.then((html) => {
				// Dismiss loading toast
				if (loadingToastId && window.toast && window.toast.dismiss) {
					window.toast.dismiss(loadingToastId);
				}

				// Process turbo stream response
				Turbo.renderStreamMessage(html);

				// Reopen drawer on moved record after DOM updates
				setTimeout(() => {
					const elementId = recordType === "Note" ? `note_${itemId}` : `item_${itemId}`;
					const movedElement = document.getElementById(elementId);
					if (movedElement) {
						movedElement.click();
					}
				}, 300);
			})
			.catch((error) => {
				console.error("Error moving item to root:", error);

				// Dismiss loading toast on error
				if (loadingToastId && window.toast && window.toast.dismiss) {
					window.toast.dismiss(loadingToastId);
				}

				// Show error toast
				if (window.toast) {
					window.toast("Failed to move item", {
						type: "error",
						description: error.message,
					});
				}
			});
	}
}
