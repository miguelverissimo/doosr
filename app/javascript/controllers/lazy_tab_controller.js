import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="lazy-tab"
export default class extends Controller {
  static targets = ["frame"]
  static values = {
    loaded: { type: Boolean, default: false }
  }

  connect() {
    // Use MutationObserver to watch for class changes (hidden class toggle)
    this.observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.type === 'attributes' && mutation.attributeName === 'class') {
          // Check if the tab content is now visible (not hidden)
          if (!this.element.classList.contains('hidden') && !this.loadedValue) {
            this.load()
          }
        }
      })
    })

    this.observer.observe(this.element, {
      attributes: true,
      attributeFilter: ['class']
    })

    // Check if tab is initially visible
    if (!this.element.classList.contains('hidden') && !this.loadedValue) {
      this.load()
    }
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  load() {
    if (this.loadedValue) return

    this.loadedValue = true

    // Load ALL frames, not just one
    if (this.hasFrameTarget) {
      this.frameTargets.forEach((frame) => {
        const src = frame.dataset.src

        if (src) {
          // Listen for frame load completion - no toast, just trigger load
          frame.addEventListener('turbo:frame-load', () => {
            // Frame loaded successfully
          }, { once: true })

          // Trigger the load by setting src attribute
          frame.setAttribute('src', src)
        }
      })
    }
  }
}
