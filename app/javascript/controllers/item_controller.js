import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static values = {
		id: Number,
		dayId: Number,
		listId: Number,
		isPublicList: Boolean,
		type: String,
	};

	openSheet(e) {
		// Don't open sheet if clicking on a form/button (like checkbox)
		if (e.target.closest("form") || e.target.closest("button")) {
			return;
		}

		// Don't open sheet if we're in moving mode
		if (sessionStorage.getItem("movingItemId")) {
			return;
		}

		// Fetch the actions sheet via Turbo
		// Use reusable_items path if we have a list_id, otherwise use items path
		let url;
		if (this.hasListIdValue) {
			url = `/reusable_items/${this.idValue}/actions`;
		} else {
			url = `/items/${this.idValue}/actions`;
		}

		const params = [];

		if (this.hasDayIdValue && this.dayIdValue) {
			params.push(`day_id=${this.dayIdValue}`);
		}

		if (this.hasListIdValue && this.listIdValue) {
			params.push(`list_id=${this.listIdValue}`);
		}

		if (this.hasIsPublicListValue && this.isPublicListValue) {
			params.push(`is_public_list=true`);
		}

		if (params.length > 0) {
			url += `?${params.join("&")}`;
		}

		fetch(url, {
			headers: {
				Accept: "text/vnd.turbo-stream.html",
			},
		})
			.then((response) => {
				return response.text();
			})
			.then((html) => {
				// Parse the turbo-stream response and extract the template content
				const parser = new DOMParser();
				const doc = parser.parseFromString(html, "text/html");
				const template = doc.querySelector("turbo-stream template");

				if (template) {
					// Get the content from the template
					const content = template.content.cloneNode(true);
					// Append directly to body
					document.body.appendChild(content);
				} else {
					console.error("No template found in turbo-stream");
				}
			})
			.catch((error) => {
				console.error("Error fetching sheet:", error);
			});
	}

	openDebug(e) {
		const itemId = e.currentTarget.dataset.itemIdValue || this.idValue;

		// Use reusable_items path if we have a list_id, otherwise use items path
		let url;
		if (this.hasListIdValue) {
			url = `/reusable_items/${itemId}/debug`;
		} else {
			url = `/items/${itemId}/debug`;
		}

		fetch(url, {
			headers: {
				Accept: "text/vnd.turbo-stream.html",
			},
		})
			.then((response) => response.text())
			.then((html) => {
				// Parse and insert manually
				const parser = new DOMParser();
				const doc = parser.parseFromString(html, "text/html");
				const template = doc.querySelector("turbo-stream template");

				if (template) {
					const content = template.content.cloneNode(true);
					document.body.appendChild(content);
				}
			})
			.catch((error) => {
				console.error("Error fetching debug:", error);
			});
	}

	toggle(e) {
		// The form will handle submission via Turbo
		// We just need to make sure the form submits
		const form = e.target.closest("form");
		if (form) {
			form.requestSubmit();
		}
	}

	stopPropagation(e) {
		e.stopPropagation();
	}

	submitForm(e) {
		const form = e.target.closest("form");
		if (form) {
			form.requestSubmit();
		}
	}
}
