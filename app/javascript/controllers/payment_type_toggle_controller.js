import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="payment-type-toggle"
export default class extends Controller {
	static targets = ["container", "switch"];

	connect() {
		// Find all payment type radio buttons in the form
		const totalRadio = this.element.querySelector(
			'input[type="radio"][value="total"][name*="payment_type"]',
		);
		const partialRadio = this.element.querySelector(
			'input[type="radio"][value="partial"][name*="payment_type"]',
		);

		// Find container - try target first, then fallback to querySelector
		let container = null;
		if (this.hasContainerTarget) {
			container = this.containerTarget;
		} else {
			container = this.element.querySelector(
				'[data-payment-type-toggle-target="container"]',
			);
		}

		if (!totalRadio || !partialRadio || !container) return;

		// Set initial state based on which radio is checked (preserve checked state on initial load)
		this.toggleSwitch(partialRadio.checked, container, true);

		// Listen for changes on both radio buttons
		const handleChange = () => {
			this.toggleSwitch(partialRadio.checked, container, false);
		};

		totalRadio.addEventListener("change", handleChange);
		partialRadio.addEventListener("change", handleChange);
	}

	toggleSwitch(isPartial, container, isInitialLoad = false) {
		if (!container) return;

		// Find the switch checkbox (Switch component uses a hidden checkbox)
		const checkbox = container.querySelector('input[type="checkbox"]');
		const switchLabel = container.querySelector('label[role="switch"]');

		if (!checkbox || !switchLabel) return;

		if (isPartial) {
			// Enable the switch when partial is selected
			checkbox.disabled = false;
			// Only uncheck on user interaction, not on initial load (preserve database value)
			if (!isInitialLoad) {
				checkbox.checked = false;
			}
			switchLabel.classList.remove("has-disabled");
			switchLabel.removeAttribute("aria-disabled");
			// Trigger change event to update the switch visual state
			checkbox.dispatchEvent(new Event("change", { bubbles: true }));
		} else {
			// Check and disable the switch when total is selected (total payment = fully paid)
			checkbox.disabled = true;
			checkbox.checked = true;
			switchLabel.classList.add("has-disabled");
			switchLabel.setAttribute("aria-disabled", "true");
			// Trigger change event to update the switch visual state
			checkbox.dispatchEvent(new Event("change", { bubbles: true }));
		}
	}
}
