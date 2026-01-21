import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  switch(event) {
    const tabId = event.currentTarget.dataset.tabId

    // Update tab styles
    this.tabTargets.forEach(tab => {
      if (tab.dataset.tabId === tabId) {
        tab.classList.remove("bg-muted", "text-muted-foreground", "hover:bg-accent")
        tab.classList.add("bg-primary", "text-primary-foreground")
      } else {
        tab.classList.remove("bg-primary", "text-primary-foreground")
        tab.classList.add("bg-muted", "text-muted-foreground", "hover:bg-accent")
      }
    })

    // Show/hide panels
    this.panelTargets.forEach(panel => {
      if (panel.dataset.panelId === tabId) {
        panel.classList.remove("hidden")
      } else {
        panel.classList.add("hidden")
      }
    })
  }
}
