import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="toast"
export default class extends Controller {
  static targets = ["container"];
  static values = {
    position: { type: String, default: "top-center" },
    layout: { type: String, default: "default" }, // "default" (stacked) or "expanded" (all visible)
    gap: { type: Number, default: 14 }, // Gap between toasts in expanded mode
    autoDismissDuration: { type: Number, default: 4000 },
    limit: { type: Number, default: 3 }, // Maximum number of visible toasts
  };

  connect() {
    // Prevent multiple toast controllers from being active
    if (window.activeToastController) {
      console.warn("Another toast controller is already active. Disconnecting this one.");
      return;
    }

    window.activeToastController = this;

    this.toasts = [];
    this.heights = []; // Track toast heights like Sonner
    this.expanded = this.layoutValue === "expanded";
    this.interacting = false;
    this.autoDismissTimers = {};

    // Store current position in a global variable that persists across interactions
    if (!window.currentToastPosition) {
      window.currentToastPosition = this.positionValue;
    } else {
      // Restore the position from the global variable
      this.positionValue = window.currentToastPosition;
    }

    // Set initial position classes
    this.updatePositionClasses();

    // Make toast function globally available
    window.toast = this.showToast.bind(this);

    // Bind event handlers so they can be properly removed
    this.boundHandleToastShow = this.handleToastShow.bind(this);
    this.boundHandleLayoutChange = this.handleLayoutChange.bind(this);
    this.boundBeforeCache = this.beforeCache.bind(this);

    // Listen for toast events
    window.addEventListener("toast-show", this.boundHandleToastShow);
    window.addEventListener("set-toasts-layout", this.boundHandleLayoutChange);
    document.addEventListener("turbo:before-cache", this.boundBeforeCache);
  }

  updatePositionClasses() {
    const container = this.containerTarget;
    // Remove all position classes
    container.classList.remove(
      "right-0",
      "left-0",
      "left-1/2",
      "-translate-x-1/2",
      "top-0",
      "bottom-0",
      "mt-4",
      "mb-4",
      "mr-4",
      "ml-4",
      "sm:mt-6",
      "sm:mb-6",
      "sm:mr-6",
      "sm:ml-6"
    );

    // Add new position classes
    const classes = this.positionClasses.split(" ");
    container.classList.add(...classes);
  }

  get positionClasses() {
    const positionMap = {
      "top-left": "left-0 top-0 mt-4 sm:mt-6 ml-4 sm:ml-6",
      "top-center": "left-1/2 -translate-x-1/2 top-0 mt-4 sm:mt-6",
      "top-right": "right-0 top-0 mt-4 sm:mt-6 mr-4 sm:mr-6",
      "bottom-left": "left-0 bottom-0 mb-4 sm:mb-6 ml-4 sm:ml-6",
      "bottom-center": "left-1/2 -translate-x-1/2 bottom-0 mb-4 sm:mb-6",
      "bottom-right": "right-0 bottom-0 mb-4 sm:mb-6 mr-4 sm:mr-6",
    };
    return positionMap[this.positionValue] || positionMap["top-center"];
  }

  disconnect() {
    // Only clean up if this is the active controller
    if (window.activeToastController === this) {
      // Remove event listeners using the bound references
      window.removeEventListener("toast-show", this.boundHandleToastShow);
      window.removeEventListener("set-toasts-layout", this.boundHandleLayoutChange);
      document.removeEventListener("turbo:before-cache", this.boundBeforeCache);

      // Clear all auto-dismiss timers
      if (this.autoDismissTimers) {
        Object.values(this.autoDismissTimers).forEach((timer) => clearTimeout(timer));
        this.autoDismissTimers = {};
      }

      // Clean up all toasts from the DOM
      this.clearAllToasts();

      // Clear global references
      window.activeToastController = null;
      window.toast = null;
    }
  }

  showToast(message, options = {}) {
    const detail = {
      type: options.type || "default",
      message: message,
      description: options.description || "",
      position: options.position || window.currentToastPosition || this.positionValue, // Use stored position
      html: options.html || "",
      action: options.action || null,
      secondaryAction: options.secondaryAction || null,
    };

    window.dispatchEvent(new CustomEvent("toast-show", { detail }));
  }

  handleToastShow(event) {
    event.stopPropagation();

    // Update container position if a position is specified for this toast
    if (event.detail.position) {
      this.positionValue = event.detail.position;
      window.currentToastPosition = event.detail.position; // Store globally
      this.updatePositionClasses();
    }

    const toast = {
      id: `toast-${Math.random().toString(16).slice(2)}`,
      mounted: false,
      removed: false,
      message: event.detail.message,
      description: event.detail.description,
      type: event.detail.type,
      html: event.detail.html,
      action: event.detail.action,
      secondaryAction: event.detail.secondaryAction,
    };

    // Add toast at the beginning of the array (newest first)
    this.toasts.unshift(toast);

    // Enforce toast limit synchronously to prevent race conditions
    const activeToasts = this.toasts.filter((t) => !t.removed);
    if (activeToasts.length > this.limitValue) {
      const oldestActiveToast = activeToasts[activeToasts.length - 1];
      if (oldestActiveToast && !oldestActiveToast.removed) {
        this.removeToast(oldestActiveToast.id, true);
      }
    }

    this.renderToast(toast);
  }

  handleLayoutChange(event) {
    this.layoutValue = event.detail.layout;
    this.expanded = this.layoutValue === "expanded";
    this.updateAllToasts();
  }

  beforeCache() {
    // Clear all toasts before the page is cached to prevent stale toasts on navigation
    this.clearAllToasts();
    // Reset position to default on navigation
    window.currentToastPosition = this.element.dataset.toastPositionValue || "top-center";
  }

  clearAllToasts() {
    // Remove all toast elements from DOM
    const container = this.containerTarget;
    if (container) {
      while (container.firstChild) {
        container.removeChild(container.firstChild);
      }
    }

    // Clear arrays
    this.toasts = [];
    this.heights = [];

    // Clear all timers
    if (this.autoDismissTimers) {
      Object.values(this.autoDismissTimers).forEach((timer) => clearTimeout(timer));
      this.autoDismissTimers = {};
    }
  }

  handleMouseEnter() {
    if (this.layoutValue === "default") {
      this.expanded = true;
      this.updateAllToasts();
    }
  }

  handleMouseLeave() {
    if (this.layoutValue === "default" && !this.interacting) {
      this.expanded = false;
      this.updateAllToasts();
    }
  }

  renderToast(toast) {
    const container = this.containerTarget;
    const li = this.createToastElement(toast);
    container.insertBefore(li, container.firstChild);

    // Measure height after a short delay to ensure rendering is complete
    requestAnimationFrame(() => {
      const toastEl = document.getElementById(toast.id);
      if (toastEl) {
        const height = toastEl.getBoundingClientRect().height;

        // Add height to the beginning of heights array
        this.heights.unshift({
          toastId: toast.id,
          height: height,
        });

        // Count only active (non-removed) toasts
        const activeToasts = this.toasts.filter((t) => !t.removed);

        // Trigger mount animation
        requestAnimationFrame(() => {
          toast.mounted = true;
          toastEl.dataset.mounted = "true";
          this.updateAllToasts();

          // Auto-dismiss
          if (this.autoDismissDurationValue > 0) {
            this.autoDismissTimers[toast.id] = setTimeout(() => {
              this.removeToast(toast.id);
            }, this.autoDismissDurationValue);
          }
        });
      }
    });
  }

  createToastElement(toast) {
    const li = document.createElement("li");
    li.id = toast.id;
    li.className = "toast-item pointer-events-auto sm:max-w-xs";
    li.dataset.mounted = "false";

    if (toast.html) {
      li.innerHTML = toast.html;
    } else {
      li.innerHTML = `
        <span class="relative flex flex-col items-start w-full transition-all duration-200 bg-white border border-neutral-200 dark:border-neutral-700 dark:bg-neutral-800 rounded-lg sm:rounded-xl shadow-lg">
          <div class="grid gap-1 p-3.5 pr-8">
            <div class="flex items-start gap-2.5">
              ${this.getIconForType(toast.type)}
              <div class="flex flex-col gap-0.5">
                ${toast.message ? `<div class="text-[13px] font-medium text-neutral-800 dark:text-neutral-200">${this.escapeHtml(toast.message)}</div>` : ""}
                ${toast.description ? `<div class="text-xs text-neutral-600 dark:text-neutral-400">${this.escapeHtml(toast.description)}</div>` : ""}
              </div>
            </div>
            ${this.getActionButtons(toast)}
          </div>
          <button
            class="toast-close-button absolute top-0 right-0 p-1.5 mr-2.5 mt-2.5 text-neutral-400 hover:bg-neutral-50 dark:hover:bg-neutral-700 rounded transition-colors"
            data-action="click->toast#removeToast"
            data-toast-id="${toast.id}"
            aria-label="Close"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M18 6L6 18M6 6l12 12"/>
            </svg>
          </button>
        </span>
      `;
    }

    return li;
  }

  getIconForType(type) {
    const icons = {
      success: `<svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 flex-shrink-0 text-green-500 dark:text-green-400" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg>`,
      info: `<svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 flex-shrink-0 text-blue-500 dark:text-blue-400" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M12 16v-4M12 8h.01"/></svg>`,
      warning: `<svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 flex-shrink-0 text-orange-400 dark:text-orange-300" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><path d="M12 9v4M12 17h.01"/></svg>`,
      danger: `<svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 flex-shrink-0 text-red-500 dark:text-red-400" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="m15 9-6 6M9 9l6 6"/></svg>`,
      default: `<svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4 flex-shrink-0 text-neutral-800 dark:text-neutral-200" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M12 16v-4M12 8h.01"/></svg>`,
    };
    return icons[type] || icons.default;
  }

  getActionButtons(toast) {
    if (!toast.action && !toast.secondaryAction) return "";

    let buttons = '<div class="flex items-center gap-2 mt-2">';
    if (toast.secondaryAction) {
      buttons += `
        <button
          class="toast-secondary-action text-xs px-2.5 py-1.5 rounded-md bg-white/90 hover:bg-neutral-50 dark:bg-neutral-800/50 dark:hover:bg-neutral-700/50 border border-neutral-200 dark:border-neutral-700 text-neutral-800 dark:text-neutral-200 transition-colors font-medium"
          data-action="click->toast#handleSecondaryAction"
          data-toast-id="${toast.id}"
        >
          ${this.escapeHtml(toast.secondaryAction.label)}
        </button>
      `;
    }
    if (toast.action) {
      buttons += `
        <button
          class="toast-action text-xs px-2.5 py-1.5 rounded-md bg-neutral-800 hover:bg-neutral-700 dark:bg-white dark:hover:bg-neutral-100 text-white dark:text-neutral-800 transition-colors font-medium"
          data-action="click->toast#handleAction"
          data-toast-id="${toast.id}"
        >
          ${this.escapeHtml(toast.action.label)}
        </button>
      `;
    }
    buttons += "</div>";
    return buttons;
  }

  handleAction(event) {
    const toastId = event.currentTarget.dataset.toastId;
    const toast = this.toasts.find((t) => t.id === toastId);
    if (toast && toast.action && toast.action.onClick) {
      toast.action.onClick();
    }
    this.removeToast(toastId);
  }

  handleSecondaryAction(event) {
    const toastId = event.currentTarget.dataset.toastId;
    const toast = this.toasts.find((t) => t.id === toastId);
    if (toast && toast.secondaryAction && toast.secondaryAction.onClick) {
      toast.secondaryAction.onClick();
    }
    this.removeToast(toastId);
  }

  removeToast(eventOrToastId, immediate = false) {
    // Handle both event object and toastId string
    const toastId = typeof eventOrToastId === 'string' 
      ? eventOrToastId 
      : eventOrToastId?.currentTarget?.dataset?.toastId || eventOrToastId?.target?.dataset?.toastId;
    
    if (!toastId) return;
    
    const toast = this.toasts.find((t) => t.id === toastId);
    if (!toast || toast.removed) return;

    toast.removed = true;

    // Clear auto-dismiss timer
    if (this.autoDismissTimers[toastId]) {
      clearTimeout(this.autoDismissTimers[toastId]);
      delete this.autoDismissTimers[toastId];
    }

    const toastEl = document.getElementById(toastId);
    if (toastEl) {
      if (immediate) {
        toastEl.remove();
        this.heights = this.heights.filter((h) => h.toastId !== toastId);
        this.toasts = this.toasts.filter((t) => t.id !== toastId);
        this.updateAllToasts();
      } else {
        toastEl.dataset.removing = "true";
        setTimeout(() => {
          if (toastEl.parentNode) {
            toastEl.remove();
          }
          this.heights = this.heights.filter((h) => h.toastId !== toastId);
          this.toasts = this.toasts.filter((t) => t.id !== toastId);
          this.updateAllToasts();
        }, 150);
      }
    }
  }

  updateAllToasts() {
    const activeToasts = this.toasts.filter((t) => !t.removed);
    let offset = 0;

    activeToasts.forEach((toast, index) => {
      const toastEl = document.getElementById(toast.id);
      if (!toastEl) return;

      const heightData = this.heights.find((h) => h.toastId === toast.id);
      const height = heightData ? heightData.height : 0;

      if (this.expanded) {
        // Expanded mode: all toasts visible with gap
        toastEl.style.transform = `translateY(${offset}px)`;
        toastEl.style.opacity = toast.mounted ? "1" : "0";
        offset += height + this.gapValue;
      } else {
        // Stacked mode: only show peek of stacked toasts
        if (index === 0) {
          // Top toast fully visible
          toastEl.style.transform = `translateY(0px)`;
          toastEl.style.opacity = toast.mounted ? "1" : "0";
        } else {
          // Stacked toasts peek
          const peekOffset = 8; // Peek amount in pixels
          toastEl.style.transform = `translateY(${offset + peekOffset}px) scale(${1 - index * 0.05})`;
          toastEl.style.opacity = toast.mounted ? "0.6" : "0";
          offset += peekOffset;
        }
      }

      toastEl.style.transition = "transform 0.2s ease-out, opacity 0.2s ease-out";
    });
  }

  escapeHtml(text) {
    const div = document.createElement("div");
    div.textContent = text;
    return div.innerHTML;
  }
}

