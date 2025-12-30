import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	static values = {
		date: String,
	};

	open() {
		const url = `/ephemeries?date=${encodeURIComponent(this.dateValue)}`;

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
				console.error("Error fetching ephemeries:", error);
			});
	}
}
