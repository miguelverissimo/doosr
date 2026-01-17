import { Controller } from "@hotwired/stimulus";
import consumer from "channels/consumer";

export default class extends Controller {
	static values = { userId: Number };

	connect() {
		if (!this.userIdValue) {
			return;
		}

		this.subscription = consumer.subscriptions.create(
			{ channel: "NotificationChannel" },
			{
				connected: () => {
					console.log("✅ Connected to notification channel");
				},

				disconnected: () => {
					console.log("❌ Disconnected from notification channel");
				},

				rejected: () => {
					console.log("🚫 Notification subscription rejected");
				},

				received: (data) => {
					if (data.html) {
						// Render the turbo stream update
						Turbo.renderStreamMessage(data.html);

						// Add pulse animation to badge
						this.animateBadge();
					}
				},
			},
		);
	}

	disconnect() {
		if (this.subscription) {
			this.subscription.unsubscribe();
		}
	}

	animateBadge() {
		const badge = document.querySelector("#notification_badge span");
		if (badge) {
			badge.classList.add("notification-badge-pulse");
			setTimeout(() => {
				badge.classList.remove("notification-badge-pulse");
			}, 1000);
		}
	}
}
