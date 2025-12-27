import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="mark-invoice-paid"
export default class extends Controller {
  static targets = ["alertDialog", "choiceDialog", "calculatorDialog", "simpleDialog"]

  connect() {
    // Use event delegation for dynamically inserted alert dialog buttons
    // Use capture phase to catch events before they're handled by other controllers
    document.addEventListener('click', this.handleDocumentClick.bind(this), true)
    
    // Listen for successful receipt form submissions to dismiss all dialogs
    document.addEventListener('turbo:submit-end', this.handleReceiptSubmitEnd.bind(this))
  }

  disconnect() {
    document.removeEventListener('click', this.handleDocumentClick.bind(this), true)
    document.removeEventListener('turbo:submit-end', this.handleReceiptSubmitEnd.bind(this))
  }

  handleReceiptSubmitEnd(event) {
    // Check if this is a receipt form submission
    const form = event.target
    const isReceiptForm = form && (
      form.action?.includes('/receipts') || 
      form.querySelector('input[name*="receipt"]') ||
      form.closest('[data-controller*="receipt"]')
    )
    
    if (isReceiptForm) {
      // Check if the submission was successful (no errors)
      const response = event.detail.fetchResponse?.response
      if (response && response.ok) {
        // Dismiss ALL dialogs IMMEDIATELY after successful receipt creation
        this.dismissAllDialogs()
      }
    }
  }

  handleDocumentClick(event) {
    // Check if the clicked element is a button or the X close button
    const button = event.target.closest('button')
    const isCloseButton = event.target.closest('button[aria-label*="close" i]') || 
                         event.target.closest('button[aria-label*="Close" i]') ||
                         event.target.closest('svg')?.closest('button')
    
    const target = button || isCloseButton
    
    if (!target) {
      // Check if clicking the backdrop (the dark overlay)
      if (event.target.classList.contains('fixed') && 
          event.target.classList.contains('inset-0') && 
          event.target.hasAttribute('data-aria-hidden')) {
        // Clicked on backdrop - dismiss all dialogs
        this.dismissAllDialogs()
        return
      }
      return
    }
    
    // Check for X close button (usually has SVG or specific classes)
    if (target.querySelector('svg') || target.classList.contains('absolute') || target.getAttribute('aria-label')?.toLowerCase().includes('close')) {
      const dialog = target.closest('[role="dialog"]') || target.closest('[role="alertdialog"]')
      if (dialog) {
        event.preventDefault()
        event.stopPropagation()
        this.dismissAllDialogs()
        return
      }
    }
    
    // First check for data attributes (more reliable)
    const receiptChoice = target.dataset.receiptChoice
    
    if (receiptChoice) {
      event.preventDefault()
      event.stopPropagation()
      
      if (receiptChoice === 'calculator') {
        this.openCalculatorForm(event)
        return
      } else if (receiptChoice === 'simple') {
        this.openSimpleForm(event)
        return
      } else if (receiptChoice === 'cancel') {
        this.cancelChoice(event)
        return
      }
    }
    
    // Fallback to text matching for alert dialog
    const buttonText = target.textContent?.trim()
    
    // Check if it's inside an alert dialog
    const alertDialog = target.closest('[role="alertdialog"]')
    if (alertDialog) {
      // Handle "Yes, Add Receipt" button
      if (buttonText === 'Yes, Add Receipt') {
        event.preventDefault()
        event.stopPropagation()
        this.confirmReceipt(event)
        return
      }
      // Handle "Cancel" button in alert dialog
      else if (buttonText === 'Cancel') {
        event.preventDefault()
        event.stopPropagation()
        this.cancelReceipt(event)
        return
      }
    }
    
    // Also check for choice dialog buttons by text (fallback)
    const dialog = target.closest('[role="dialog"]')
    if (dialog) {
      const dialogTitle = dialog.querySelector('h2')?.textContent?.trim()
      
      if (dialogTitle === 'Choose Receipt Form') {
        if (buttonText === 'With Calculator') {
          event.preventDefault()
          event.stopPropagation()
          this.openCalculatorForm(event)
          return
        } else if (buttonText === 'Simple Form') {
          event.preventDefault()
          event.stopPropagation()
          this.openSimpleForm(event)
          return
        } else if (buttonText === 'Cancel') {
          event.preventDefault()
          event.stopPropagation()
          this.cancelChoice(event)
          return
        }
      }
    }
  }

  async submit(event) {
    event.preventDefault()
    
    // Show loading toast immediately
    if (window.toast) {
      this.loadingToastId = window.toast('Marking invoice as paid...', {
        type: 'loading',
        description: 'Please wait'
      })
    }
    
    const form = event.target.closest('form')
    const formData = new FormData(form)
    const url = form.action
    
    // Extract invoice ID from URL for finding the dialog after update
    const invoiceIdMatch = url.match(/\/invoices\/(\d+)/)
    const invoiceId = invoiceIdMatch ? invoiceIdMatch[1] : null
    
    // Store invoice ID in multiple places for persistence
    this.invoiceId = invoiceId
    // Also store it in a data attribute on the controller element so it persists across DOM updates
    if (invoiceId) {
      this.element.dataset.invoiceId = invoiceId
      // Also store in sessionStorage as backup
      sessionStorage.setItem('lastMarkedPaidInvoiceId', invoiceId)
    }
    
    // Get CSRF token from meta tag
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    
    // Use POST method with _method override in form data (Rails pattern)
    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': csrfToken,
          'Accept': 'text/vnd.turbo-stream.html'
        },
        body: formData
      })

      // Dismiss loading toast
      if (window.toast && window.toast.dismiss && this.loadingToastId) {
        window.toast.dismiss(this.loadingToastId)
        this.loadingToastId = null
      }

      if (response.ok) {
        // Show success toast immediately
        window.toast && window.toast('Invoice marked as paid', { type: 'success' })
        
        const html = await response.text()
        Turbo.renderStreamMessage(html)
        
        // Wait for Turbo to finish updating the DOM, then show alert dialog
        // Use invoice ID to find the dialog in the updated DOM
        setTimeout(() => {
          this.showReceiptPrompt(invoiceId)
        }, 500)
      } else {
        const errorText = await response.text()
        window.toast && window.toast('Failed to update invoice', { type: 'error' })
      }
    } catch (error) {
      // Dismiss loading toast on error
      if (window.toast && window.toast.dismiss && this.loadingToastId) {
        window.toast.dismiss(this.loadingToastId)
        this.loadingToastId = null
      }
      
      window.toast && window.toast('Failed to update invoice', { type: 'error' })
    }
  }

  showReceiptPrompt(invoiceId) {
    // Find the alert dialog in the updated DOM
    // Look for the alert dialog within the invoice row
    const invoiceDiv = invoiceId ? document.querySelector(`#invoice_${invoiceId}_div`) : null
    const alertDialogElement = invoiceDiv 
      ? invoiceDiv.querySelector('[data-controller*="ruby-ui--alert-dialog"][data-mark-invoice-paid-target="alertDialog"]')
      : document.querySelector('[data-controller*="ruby-ui--alert-dialog"][data-mark-invoice-paid-target="alertDialog"]')
    
    if (alertDialogElement) {
      // Get the controller for the alert dialog
      const alertDialogController = this.application.getControllerForElementAndIdentifier(
        alertDialogElement,
        'ruby-ui--alert-dialog'
      )
      
      if (alertDialogController) {
        alertDialogController.open()
      }
    }
  }

  cancelReceipt(event) {
    this.dismissAlertDialog()
  }

  confirmReceipt(event) {
    event?.preventDefault()
    event?.stopPropagation()
    
    // Get invoice ID from multiple sources (in order of preference)
    const invoiceId = this.invoiceId || 
                     this.element.dataset.invoiceId || 
                     sessionStorage.getItem('lastMarkedPaidInvoiceId') ||
                     this.element.closest('[id^="invoice_"]')?.id.match(/invoice_(\d+)/)?.[1]
    
    if (!invoiceId) {
      window.toast && window.toast('Error: Could not find invoice ID', { type: 'error' })
      return
    }
    
    // Store it again to ensure it's available
    this.invoiceId = invoiceId
    this.element.dataset.invoiceId = invoiceId
    
    this.dismissAlertDialog()
    
    // Wait a bit before opening the choice dialog to ensure the alert is fully dismissed
    setTimeout(() => {
      this.showReceiptChoiceDialog(invoiceId)
    }, 300)
  }

  dismissAllDialogs() {
    // Remove ALL elements that were inserted into body by dialogs
    // This includes the actual dialog content, backdrops, and containers
    
    // Remove all alert dialogs (the actual content inserted into body)
    document.querySelectorAll('[role="alertdialog"]').forEach(el => {
      el.remove()
    })
    
    // Remove all regular dialogs (the actual content inserted into body)
    document.querySelectorAll('[role="dialog"]').forEach(el => {
      el.remove()
    })
    
    // Remove all backdrops (the dark overlay) - be more aggressive
    document.querySelectorAll('[data-aria-hidden="true"]').forEach(el => {
      el.remove()
    })
    
    // Remove any fixed positioned overlays
    document.querySelectorAll('.fixed.inset-0').forEach(el => {
      if (el.classList.contains('bg-black') || el.classList.contains('bg-background')) {
        el.remove()
      }
    })
    
    // Remove any dialog containers inserted into body
    // These are the divs with data-controller that get inserted
    const bodyChildren = Array.from(document.body.children)
    bodyChildren.forEach(el => {
      if (el.hasAttribute('data-controller')) {
        const controller = el.getAttribute('data-controller')
        if (controller && (controller.includes('ruby-ui--dialog') || controller.includes('ruby-ui--alert-dialog'))) {
          el.remove()
        }
      }
      // Also check for divs that contain dialog content
      if (el.querySelector && (el.querySelector('[role="dialog"]') || el.querySelector('[role="alertdialog"]'))) {
        el.remove()
      }
    })
    
    // Remove overflow-hidden class
    document.body.classList.remove('overflow-hidden')
    
    // Force a reflow to ensure everything is removed
    document.body.offsetHeight
  }

  dismissAlertDialog() {
    this.dismissAllDialogs()
  }

  showReceiptChoiceDialog(invoiceId) {
    // First, dismiss any existing dialogs
    this.dismissAllDialogs()
    
    // Wait a moment for cleanup
    setTimeout(() => {
      // Find the choice dialog in the DOM
      const invoiceDiv = invoiceId ? document.querySelector(`#invoice_${invoiceId}_div`) : null
      const choiceDialogElement = invoiceDiv
        ? invoiceDiv.querySelector('[data-controller*="ruby-ui--dialog"][data-mark-invoice-paid-target="choiceDialog"]')
        : document.querySelector('[data-controller*="ruby-ui--dialog"][data-mark-invoice-paid-target="choiceDialog"]')
      
      if (choiceDialogElement) {
        const choiceDialogController = this.application.getControllerForElementAndIdentifier(
          choiceDialogElement,
          'ruby-ui--dialog'
        )
        if (choiceDialogController) {
          choiceDialogController.open()
        }
      }
    }, 100)
  }

  cancelChoice(event) {
    this.dismissAllDialogs()
  }

  dismissChoiceDialog() {
    this.dismissAllDialogs()
  }

  openCalculatorForm(event) {
    event?.preventDefault()
    event?.stopPropagation()
    
    // Get invoice ID from multiple sources
    const invoiceId = this.invoiceId || 
                     this.element.dataset.invoiceId || 
                     sessionStorage.getItem('lastMarkedPaidInvoiceId') ||
                     event.target.closest('[id^="invoice_"]')?.id.match(/invoice_(\d+)/)?.[1]
    
    if (!invoiceId) {
      window.toast && window.toast('Error: Could not find invoice ID', { type: 'error' })
      return
    }
    
    // Dismiss ALL dialogs FIRST - no delay, do it immediately
    this.dismissAllDialogs()
    
    // Find the calculator dialog and open it immediately
    const invoiceDiv = document.querySelector(`#invoice_${invoiceId}_div`)
    const calculatorDialogElement = invoiceDiv
      ? invoiceDiv.querySelector('[data-controller*="ruby-ui--dialog"][data-mark-invoice-paid-target="calculatorDialog"]')
      : document.querySelector('[data-controller*="ruby-ui--dialog"][data-mark-invoice-paid-target="calculatorDialog"]')
    
    if (calculatorDialogElement) {
      const calculatorDialogController = this.application.getControllerForElementAndIdentifier(
        calculatorDialogElement,
        'ruby-ui--dialog'
      )
      if (calculatorDialogController) {
        // Small delay to ensure previous dialog is gone
        setTimeout(() => {
          calculatorDialogController.open()
        }, 50)
      }
    }
  }

  openSimpleForm(event) {
    event?.preventDefault()
    event?.stopPropagation()
    
    // Get invoice ID from multiple sources
    const invoiceId = this.invoiceId || 
                     this.element.dataset.invoiceId || 
                     sessionStorage.getItem('lastMarkedPaidInvoiceId') ||
                     event.target.closest('[id^="invoice_"]')?.id.match(/invoice_(\d+)/)?.[1]
    
    if (!invoiceId) {
      window.toast && window.toast('Error: Could not find invoice ID', { type: 'error' })
      return
    }
    
    // Dismiss ALL dialogs FIRST - no delay, do it immediately
    this.dismissAllDialogs()
    
    // Find the simple form dialog and open it immediately
    const invoiceDiv = document.querySelector(`#invoice_${invoiceId}_div`)
    const simpleDialogElement = invoiceDiv
      ? invoiceDiv.querySelector('[data-controller*="ruby-ui--dialog"][data-mark-invoice-paid-target="simpleDialog"]')
      : document.querySelector('[data-controller*="ruby-ui--dialog"][data-mark-invoice-paid-target="simpleDialog"]')
    
    if (simpleDialogElement) {
      const simpleDialogController = this.application.getControllerForElementAndIdentifier(
        simpleDialogElement,
        'ruby-ui--dialog'
      )
      if (simpleDialogController) {
        // Small delay to ensure previous dialog is gone
        setTimeout(() => {
          simpleDialogController.open()
        }, 50)
      }
    }
  }
}

