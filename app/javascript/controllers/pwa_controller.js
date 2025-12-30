import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
	connect() {
		this.registerServiceWorker();
	}

	async registerServiceWorker() {
		if ("serviceWorker" in navigator) {
			try {
				const registration = await navigator.serviceWorker.register(
					"/service-worker.js",
					{
						scope: "/",
					},
				);

				// Check for updates periodically
				setInterval(() => {
					registration.update();
				}, 60000); // Check every minute

				// Handle updates
				registration.addEventListener("updatefound", () => {
					const newWorker = registration.installing;

					newWorker.addEventListener("statechange", () => {
						if (
							newWorker.state === "activated" &&
							navigator.serviceWorker.controller
						) {
							// New service worker activated, could show update notification
							console.log("New service worker activated");
						}
					});
				});
			} catch (error) {
				console.error("ServiceWorker registration failed:", error);
			}
		}
	}
}
