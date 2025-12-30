import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="mark-invoice-paid"
export default class extends Controller {
  static targets = ["alertDialog", "choiceDialog", "calculatorDialog", "simpleDialog", "markPaidForm"]
  static values = { invoiceId: String }

  connect() {
    document.addEventListener('turbo:submit-end', this.handleReceiptSubmitEnd.bind(this))
    window.openReceiptChoice = this.openReceiptChoiceGlobal.bind(this)
  }

  disconnect() {
    document.removeEventListener('turbo:submit-end', this.handleReceiptSubmitEnd.bind(this))
  }

  async handleReceiptSubmitEnd(event) {
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
        await this.dismissAllDialogs()
      }
    }
  }

  async startFlow(event) {
    const invoiceId = event.currentTarget.dataset.invoiceId

    if (!invoiceId) {
      window.toast && window.toast('Error: Could not find invoice ID', { type: 'error' })
      return
    }

    this.invoiceId = invoiceId
    this.element.dataset.invoiceId = invoiceId
    sessionStorage.setItem('lastMarkedPaidInvoiceId', invoiceId)

    this.showReceiptPrompt(invoiceId)
  }

  showReceiptPrompt(invoiceId) {
    const invoiceDiv = invoiceId ? document.querySelector(`#invoice_${invoiceId}_div`) : null
    const alertDialogElement = invoiceDiv
      ? invoiceDiv.querySelector('[data-controller*="ruby-ui--alert-dialog"][data-mark-invoice-paid-target="alertDialog"]')
      : document.querySelector('[data-controller*="ruby-ui--alert-dialog"][data-mark-invoice-paid-target="alertDialog"]')

    if (alertDialogElement) {
      const alertDialogController = this.application.getControllerForElementAndIdentifier(
        alertDialogElement,
        'ruby-ui--alert-dialog'
      )

      if (alertDialogController) {
        alertDialogController.open()

        setTimeout(() => {
          document.addEventListener('click', (e) => {
            const target = e.target.closest('button[data-receipt-choice="yes"]')
            if (target && target.dataset.invoiceId === invoiceId.toString()) {
              setTimeout(() => {
                this.showReceiptChoiceDialog(invoiceId)
              }, 300)
            }
          }, { once: true, capture: true })
        }, 100)
      }
    }
  }

  cancelReceipt(event) {
    event?.preventDefault()
    event?.stopPropagation()

    const invoiceId = this.invoiceIdValue || this.invoiceId || this.element.dataset.invoiceId || sessionStorage.getItem('lastMarkedPaidInvoiceId')

    if (!invoiceId) {
      window.toast && window.toast('Error: Could not find invoice ID', { type: 'error' })
      return
    }

    const invoiceDiv = document.querySelector(`#invoice_${invoiceId}_div`)
    if (!invoiceDiv) return

    const mainController = this.application.getControllerForElementAndIdentifier(invoiceDiv, 'mark-invoice-paid')
    if (!mainController) return

    const alertDialogElement = invoiceDiv.querySelector('[data-controller*="ruby-ui--alert-dialog"][data-mark-invoice-paid-target="alertDialog"]')
    if (alertDialogElement) {
      const alertDialogController = this.application.getControllerForElementAndIdentifier(
        alertDialogElement,
        'ruby-ui--alert-dialog'
      )
      if (alertDialogController && alertDialogController.close) {
        alertDialogController.close()
      }
    }

    mainController.markInvoicePaid()
  }

  confirmReceipt(event) {
    const invoiceId = event.currentTarget?.dataset?.invoiceId || this.invoiceIdValue
    if (!invoiceId) return

    document.querySelectorAll('[role="alertdialog"]').forEach(dialog => dialog.remove())
    document.querySelectorAll('[data-aria-hidden="true"]').forEach(el => el.remove())
    document.body.classList.remove('overflow-hidden')

    setTimeout(() => {
      const invoiceDiv = document.querySelector(`#invoice_${invoiceId}_div`)
      const choiceDialogElement = invoiceDiv?.querySelector('[data-mark-invoice-paid-target="choiceDialog"]')

      if (choiceDialogElement) {
        const choiceDialogController = this.application.getControllerForElementAndIdentifier(
          choiceDialogElement,
          'ruby-ui--dialog'
        )
        if (choiceDialogController?.open) {
          choiceDialogController.open()
        }
      }
    }, 200)
  }

  dismissAllDialogs() {
    return new Promise((resolve) => {
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
        if (el.classList.contains('bg-black') || el.classList.contains('bg-background') || el.style.backgroundColor) {
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

      // Wait a bit to ensure DOM is fully cleaned up
      setTimeout(resolve, 100)
    })
  }

  showReceiptChoiceDialog(invoiceId) {
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
  }

  cancelChoice(event) {
    const invoiceId = event.currentTarget?.dataset?.invoiceId || this.invoiceIdValue
    if (!invoiceId) return

    const invoiceDiv = document.querySelector(`#invoice_${invoiceId}_div`)
    const mainController = this.application.getControllerForElementAndIdentifier(invoiceDiv, 'mark-invoice-paid')
    if (mainController) {
      mainController.markInvoicePaid()
    }
  }

  openCalculatorForm(event) {
    const invoiceId = event.currentTarget?.dataset?.invoiceId || this.invoiceIdValue
    if (!invoiceId) return

    setTimeout(() => {
      const invoiceDiv = document.querySelector(`#invoice_${invoiceId}_div`)
      const calculatorDialogElement = invoiceDiv?.querySelector('[data-mark-invoice-paid-target="calculatorDialog"]')

      if (calculatorDialogElement) {
        const calculatorDialogController = this.application.getControllerForElementAndIdentifier(
          calculatorDialogElement,
          'ruby-ui--dialog'
        )
        if (calculatorDialogController?.open) {
          calculatorDialogController.open()
        }
      }
    }, 150)
  }

  openSimpleForm(event) {
    const invoiceId = event.currentTarget?.dataset?.invoiceId || this.invoiceIdValue
    if (!invoiceId) return

    setTimeout(() => {
      const invoiceDiv = document.querySelector(`#invoice_${invoiceId}_div`)
      const simpleDialogElement = invoiceDiv?.querySelector('[data-mark-invoice-paid-target="simpleDialog"]')

      if (simpleDialogElement) {
        const simpleDialogController = this.application.getControllerForElementAndIdentifier(
          simpleDialogElement,
          'ruby-ui--dialog'
        )
        if (simpleDialogController?.open) {
          simpleDialogController.open()
        }
      }
    }, 150)
  }

  openReceiptChoiceGlobal(invoiceId) {
    document.querySelectorAll('[role="alertdialog"]').forEach(dialog => dialog.remove())
    document.querySelectorAll('[data-aria-hidden="true"]').forEach(el => el.remove())
    document.body.classList.remove('overflow-hidden')

    setTimeout(() => {
      const invoiceDiv = document.querySelector(`#invoice_${invoiceId}_div`)
      const choiceDialogElement = invoiceDiv?.querySelector('[data-controller*="ruby-ui--dialog"][data-mark-invoice-paid-target="choiceDialog"]')

      if (choiceDialogElement) {
        const choiceDialogController = this.application.getControllerForElementAndIdentifier(
          choiceDialogElement,
          'ruby-ui--dialog'
        )
        if (choiceDialogController && choiceDialogController.open) {
          choiceDialogController.open()
        }
      }
    }, 200)
  }

  markInvoicePaid() {
    if (!this.hasMarkPaidFormTarget) return

    // Show loading toast
    if (window.toast) {
      this.loadingToastId = window.toast('Marking invoice as paid...', {
        type: 'loading',
        description: 'Please wait'
      })
    }

    // Submit the form
    const formData = new FormData(this.markPaidFormTarget)
    const url = this.markPaidFormTarget.action
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(url, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Accept': 'text/vnd.turbo-stream.html'
      },
      body: formData
    })
    .then(response => {
      // Dismiss loading toast
      if (window.toast && window.toast.dismiss && this.loadingToastId) {
        window.toast.dismiss(this.loadingToastId)
        this.loadingToastId = null
      }

      if (response.ok) {
        window.toast && window.toast('Invoice marked as paid', { type: 'success' })
        return response.text()
      } else {
        throw new Error('Failed to mark invoice as paid')
      }
    })
    .then(html => {
      if (html) {
        Turbo.renderStreamMessage(html)
      }
    })
    .catch(error => {
      // Dismiss loading toast on error
      if (window.toast && window.toast.dismiss && this.loadingToastId) {
        window.toast.dismiss(this.loadingToastId)
        this.loadingToastId = null
      }

      window.toast && window.toast('Failed to mark invoice as paid', { type: 'error' })
    })
  }
}
