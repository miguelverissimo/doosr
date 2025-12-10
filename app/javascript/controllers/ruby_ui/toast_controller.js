import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]
  static values = {
    position: { type: String, default: "top-center" },
    layout: { type: String, default: "default" },
    gap: { type: Number, default: 14 },
    autoDismissDuration: { type: Number, default: 4000 },
    limit: { type: Number, default: 3 }
  }

  connect() {
    // Make toast function available globally
    window.toast = this.show.bind(this)
    console.log("✅ Toast controller connected, window.toast is now available")
    this.updatePosition()
  }

  disconnect() {
    window.toast = null
  }

  show(message, options = {}) {
    const {
      type = "default",
      description = "",
      duration,
      icon,
      position = this.positionValue
    } = options

    // Determine auto-dismiss duration
    let dismissDuration = duration !== undefined ? duration : this.autoDismissDurationValue
    if (type === "loading") {
      dismissDuration = 0 // Don't auto-dismiss loading toasts
    }

    const toastId = `toast-${Date.now()}-${Math.random()}`
    const toastElement = this.createToastElement(toastId, message, description, type, icon)

    // Update container position if needed
    if (position !== this.positionValue) {
      this.updatePosition(position)
    }

    this.containerTarget.appendChild(toastElement)

    // Trigger mount animation
    requestAnimationFrame(() => {
      toastElement.dataset.mounted = "true"
    })

    // Auto dismiss
    if (dismissDuration > 0) {
      setTimeout(() => {
        this.dismiss(toastId)
      }, dismissDuration)
    }

    return toastId
  }

  createToastElement(id, message, description, type, customIcon) {
    const li = document.createElement("li")
    li.id = id
    li.className = "group pointer-events-auto relative flex w-full items-center space-x-3 overflow-hidden rounded-lg sm:rounded-xl border border-neutral-200 dark:border-neutral-700 bg-white dark:bg-neutral-800 p-4 pr-8 shadow-xs transition-all duration-200 data-[mounted=true]:animate-in data-[removed=true]:animate-out data-[removed=true]:fade-out-80 data-[removed=true]:slide-out-to-right-full data-[mounted=true]:slide-in-from-top-full data-[mounted=true]:sm:slide-in-from-bottom-full"
    li.style.marginBottom = `${this.gapValue}px`
    li.dataset.mounted = "false"

    // Icon
    const iconEl = document.createElement("div")
    iconEl.className = `shrink-0 ${this.getIconColorClass(type)}`
    iconEl.innerHTML = customIcon || this.getIcon(type)

    // Content
    const content = document.createElement("div")
    content.className = "grid gap-1 flex-1"

    const title = document.createElement("div")
    title.className = "text-[13px] font-medium text-neutral-800 dark:text-neutral-200 leading-none"
    title.textContent = message

    content.appendChild(title)

    if (description) {
      const desc = document.createElement("div")
      desc.className = "text-xs text-neutral-600 dark:text-neutral-400"
      desc.textContent = description
      content.appendChild(desc)
    }

    // Close button
    const closeButton = document.createElement("button")
    closeButton.type = "button"
    closeButton.className = "absolute right-2 top-2 rounded-md p-1 text-foreground/50 opacity-0 transition-opacity hover:text-foreground focus:opacity-100 focus:outline-none group-hover:opacity-100"
    closeButton.innerHTML = `
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M18 6 6 18M6 6l12 12"/>
      </svg>
    `
    closeButton.onclick = () => this.dismiss(id)

    li.appendChild(iconEl)
    li.appendChild(content)
    li.appendChild(closeButton)

    return li
  }

  getIcon(type) {
    const icons = {
      success: `<svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>`,
      error: `<svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="m15 9-6 6m0-6 6 6"/></svg>`,
      danger: `<svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><path d="M12 9v4m0 4h.01"/></svg>`,
      warning: `<svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><path d="M12 9v4m0 4h.01"/></svg>`,
      info: `<svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M12 16v-4m0-4h.01"/></svg>`,
      loading: `<svg class="h-5 w-5 animate-spin" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12a9 9 0 1 1-6.219-8.56"/></svg>`,
      default: ``
    }
    return icons[type] || icons.default
  }

  getIconColorClass(type) {
    const colors = {
      success: "text-green-500 dark:text-green-400",
      error: "text-red-500 dark:text-red-400",
      danger: "text-red-500 dark:text-red-400",
      warning: "text-orange-500 dark:text-orange-400",
      info: "text-blue-500 dark:text-blue-400",
      loading: "text-neutral-600 dark:text-neutral-400",
      default: "text-neutral-600 dark:text-neutral-400"
    }
    return colors[type] || colors.default
  }

  updatePosition(position = this.positionValue) {
    const positions = {
      "top-left": "top-0 left-0 mt-4 sm:mt-6 ml-4 sm:ml-6",
      "top-center": "top-0 left-1/2 -translate-x-1/2 mt-4 sm:mt-6",
      "top-right": "top-0 right-0 mt-4 sm:mt-6 mr-4 sm:mr-6",
      "bottom-left": "bottom-0 left-0 mb-4 sm:mb-6 ml-4 sm:ml-6",
      "bottom-center": "bottom-0 left-1/2 -translate-x-1/2 mb-4 sm:mb-6",
      "bottom-right": "bottom-0 right-0 mb-4 sm:mb-6 mr-4 sm:mr-6"
    }

    // Remove all position classes
    Object.values(positions).forEach(cls => {
      cls.split(' ').forEach(c => this.containerTarget.classList.remove(c))
    })

    // Add new position classes
    const newClasses = positions[position] || positions["top-center"]
    newClasses.split(' ').forEach(cls => {
      this.containerTarget.classList.add(cls)
    })
  }

  dismiss(toastId) {
    const toast = document.getElementById(toastId)
    if (toast) {
      toast.dataset.removed = "true"
      setTimeout(() => {
        toast.remove()
      }, 300)
    }
  }

  handleMouseEnter() {
    // Pause auto-dismiss on hover if needed
  }

  handleMouseLeave() {
    // Resume auto-dismiss if needed
  }
}
