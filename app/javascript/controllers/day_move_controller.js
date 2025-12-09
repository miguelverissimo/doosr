import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "cancelButton", "rootTarget"]
  static values = { dayId: Number }

  connect() {
    console.log("Day move controller connected")

    // Check if we're returning from a moving mode
    const movingItemId = sessionStorage.getItem('movingItemId')
    if (movingItemId) {
      this.enterMovingMode(parseInt(movingItemId))
    }

    // Listen for moving mode events
    this.boundStartMoving = this.handleStartMoving.bind(this)
    this.boundCancelMoving = this.handleCancelMoving.bind(this)
    this.boundEscapeKey = this.handleEscapeKey.bind(this)

    window.addEventListener('item:start-moving', this.boundStartMoving)
    window.addEventListener('item:cancel-moving', this.boundCancelMoving)
    document.addEventListener('keydown', this.boundEscapeKey)
  }

  disconnect() {
    window.removeEventListener('item:start-moving', this.boundStartMoving)
    window.removeEventListener('item:cancel-moving', this.boundCancelMoving)
    document.removeEventListener('keydown', this.boundEscapeKey)
  }

  handleStartMoving(event) {
    console.log("Handling start moving event:", event.detail)
    this.enterMovingMode(event.detail.itemId)
  }

  handleCancelMoving(event) {
    console.log("Handling cancel moving event")
    this.exitMovingMode()

    // Reopen the drawer on the original item
    const itemElement = document.getElementById(`item_${event.detail.itemId}`)
    if (itemElement) {
      setTimeout(() => {
        itemElement.click()
      }, 100)
    }
  }

  handleEscapeKey(event) {
    if (event.key === 'Escape' && this.isInMovingMode()) {
      event.preventDefault()
      this.cancelMoving()
    }
  }

  enterMovingMode(itemId) {
    console.log("Entering moving mode for item:", itemId)

    this.movingItemId = itemId

    // Store in sessionStorage for persistence
    sessionStorage.setItem('movingItemId', itemId)
    sessionStorage.setItem('movingDayId', this.dayIdValue)

    // Show cancel button
    if (this.hasCancelButtonTarget) {
      this.cancelButtonTarget.classList.remove('hidden')
    }

    // Check if item is at root level (direct child of items_list)
    const itemElement = document.getElementById(`item_${itemId}`)
    const isAtRootLevel = itemElement && itemElement.parentElement.id === 'items_list'
    console.log("Item is at root level:", isAtRootLevel)

    // Only show root target if item is NOT already at root level
    if (this.hasRootTargetTarget && !isAtRootLevel) {
      this.rootTargetTarget.classList.remove('hidden')
    }

    // Highlight the moving item
    if (itemElement) {
      itemElement.classList.add('bg-pink-500/20', 'border-pink-500')
    }

    // Highlight all other items as targets
    this.itemTargets.forEach(item => {
      const currentItemId = parseInt(item.dataset.itemMovingItemIdValue || item.dataset.itemIdValue)
      if (currentItemId !== itemId) {
        item.classList.add('border-2', 'border-dashed', 'border-primary', 'cursor-pointer')
        // Replace the action with selectTarget during moving mode
        item.dataset.action = 'click->day-move#selectTarget'
        item.dataset.dayMoveTargetItemId = currentItemId
      }
    })
  }

  exitMovingMode() {
    console.log("Exiting moving mode")

    // Hide cancel button
    if (this.hasCancelButtonTarget) {
      this.cancelButtonTarget.classList.add('hidden')
    }

    // Hide root target (always, since it might have been shown)
    if (this.hasRootTargetTarget) {
      this.rootTargetTarget.classList.add('hidden')
    }

    // Remove highlights from moving item
    if (this.movingItemId) {
      const itemElement = document.getElementById(`item_${this.movingItemId}`)
      if (itemElement) {
        itemElement.classList.remove('bg-pink-500/20', 'border-pink-500')
      }
    }

    // Remove highlights from all target items
    this.itemTargets.forEach(item => {
      item.classList.remove('border-2', 'border-dashed', 'border-primary', 'cursor-pointer')
      // Remove the dynamic action we added (keep original actions)
      const originalAction = 'click->item#openSheet'
      item.dataset.action = originalAction
      delete item.dataset.dayMoveTargetItemId
    })

    // Clear session storage
    sessionStorage.removeItem('movingItemId')
    sessionStorage.removeItem('movingDayId')

    this.movingItemId = null
  }

  isInMovingMode() {
    return this.movingItemId != null
  }

  cancelMoving() {
    console.log("Canceling moving mode")
    const movingItemId = this.movingItemId

    // Exit moving mode (clears sessionStorage and resets UI)
    this.exitMovingMode()

    // Reopen the drawer on the original item
    if (movingItemId) {
      const itemElement = document.getElementById(`item_${movingItemId}`)
      if (itemElement) {
        setTimeout(() => {
          console.log("Reopening drawer for item:", movingItemId)
          itemElement.click()
        }, 100)
      }
    }
  }

  selectTarget(event) {
    if (!this.isInMovingMode()) return

    event.stopPropagation()
    event.preventDefault()

    const targetItemId = parseInt(event.currentTarget.dataset.dayMoveTargetItemId)
    console.log("Selected target item:", targetItemId)

    this.moveItemToTarget(this.movingItemId, targetItemId)
  }

  selectRootTarget(event) {
    console.log("selectRootTarget called, moving mode:", this.isInMovingMode(), "movingItemId:", this.movingItemId)

    if (!this.isInMovingMode()) {
      console.log("Not in moving mode, returning")
      return
    }

    event.stopPropagation()
    event.preventDefault()

    console.log("Selected root target, moving item", this.movingItemId, "to root")
    this.moveItemToRoot(this.movingItemId)
  }

  moveItemToTarget(itemId, targetItemId) {
    console.log(`Moving item ${itemId} to target ${targetItemId}`)

    // Exit moving mode first
    this.exitMovingMode()

    // Clear session storage
    sessionStorage.removeItem('movingItemId')
    sessionStorage.removeItem('movingDayId')

    // Make the reparent request
    fetch(`/items/${itemId}/reparent`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'text/vnd.turbo-stream.html',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        target_item_id: targetItemId,
        day_id: this.dayIdValue
      })
    })
    .then(response => response.text())
    .then(html => {
      console.log("Received turbo stream response for moveToTarget, length:", html.length)

      // Process turbo stream response
      Turbo.renderStreamMessage(html)

      console.log("Turbo stream processed, waiting for DOM update")

      // Reopen drawer on moved item after DOM updates
      setTimeout(() => {
        const movedItem = document.getElementById(`item_${itemId}`)
        console.log("Looking for moved item:", itemId, "found:", movedItem !== null)
        if (movedItem) {
          movedItem.click()
        }
      }, 300)
    })
    .catch(error => {
      console.error('Error moving item:', error)
      alert('Failed to move item')
    })
  }

  moveItemToRoot(itemId) {
    console.log(`Moving item ${itemId} to root`)

    // Exit moving mode first
    this.exitMovingMode()

    // Clear session storage
    sessionStorage.removeItem('movingItemId')
    sessionStorage.removeItem('movingDayId')

    // Make the reparent request
    fetch(`/items/${itemId}/reparent`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'text/vnd.turbo-stream.html',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        target_item_id: null,
        day_id: this.dayIdValue
      })
    })
    .then(response => response.text())
    .then(html => {
      console.log("Received turbo stream response for moveToRoot, length:", html.length)

      // Process turbo stream response
      Turbo.renderStreamMessage(html)

      console.log("Turbo stream processed, waiting for DOM update")

      // Reopen drawer on moved item after DOM updates
      setTimeout(() => {
        const movedItem = document.getElementById(`item_${itemId}`)
        console.log("Looking for moved item:", itemId, "found:", movedItem !== null)
        if (movedItem) {
          movedItem.click()
        }
      }, 300)
    })
    .catch(error => {
      console.error('Error moving item to root:', error)
      alert('Failed to move item')
    })
  }
}
