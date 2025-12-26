import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "valueInput",
    "manevHSlider",
    "manevOnCallSlider",
    "tokenSlider",
    "manevHDisplay",
    "manevOnCallDisplay",
    "tokenDisplay",
    "manevHAmount",
    "manevOnCallAmount",
    "tokenAmount",
    "totalDisplay",
    "manevHQuantity",
    "manevHValueWithTax",
    "manevOnCallQuantity",
    "manevOnCallValueWithTax",
    "tokenQuantity",
    "tokenValueWithTax"
  ]
  static values = {
    manevHUnitPrice: Number,
    manevOnCallUnitPrice: Number,
    tokenUnitPrice: Number
  }

  connect() {
    // Check if required targets exist
    if (!this.hasValueInputTarget) {
      console.warn("Receipt calculator: valueInput target not found")
      return
    }

    // Set a high initial max for manevOnCallSlider (will be adjusted dynamically based on budget)
    if (this.hasManevOnCallSliderTarget) {
      this.manevOnCallSliderTarget.max = 10000
    }
    
    // Initialize with value if present
    if (this.valueInputTarget.value && this.valueInputTarget.value !== "") {
      this.initializeFromValue()
    } else {
      this.resetAll()
    }
  }

  onValueChange() {
    this.initializeFromValue()
  }

  onManevHChange() {
    this.adjustManevH()
  }

  onManevOnCallChange() {
    this.adjustManevOnCall()
  }

  initializeFromValue() {
    if (!this.hasValueInputTarget) return
    
    const totalValue = this.getTotalValueInCents()
    if (totalValue <= 0) {
      this.resetAll()
      return
    }

    // Check if we have the required sliders
    if (!this.hasManevHSliderTarget || !this.hasManevOnCallSliderTarget) {
      // Just update total display if sliders aren't available
      if (this.hasTotalDisplayTarget) {
        this.totalDisplayTarget.textContent = this.formatCurrency(totalValue / 100)
      }
      return
    }

    // Start with 1 unit of "OUT - MANEV-ON-CALL"
    const onCallUnits = 1
    const onCallAmount = onCallUnits * this.manevOnCallUnitPriceValue

    // Calculate remaining budget for "OUT - MANEV-H"
    const remainingBudget = totalValue - onCallAmount

    // Calculate how many units of "OUT - MANEV-H" fit in remaining budget
    const manevHUnits = Math.floor(remainingBudget / this.manevHUnitPriceValue)
    
    // Clamp to valid range (110-176)
    const clampedManevHUnits = Math.max(110, Math.min(176, manevHUnits))

    // Calculate max for "OUT - MANEV-ON-CALL" based on clamped "OUT - MANEV-H"
    const finalManevHAmount = clampedManevHUnits * this.manevHUnitPriceValue
    const finalRemainingBudget = totalValue - finalManevHAmount
    const maxOnCallUnits = Math.max(1, Math.floor(finalRemainingBudget / this.manevOnCallUnitPriceValue))

    // Set the sliders
    this.manevHSliderTarget.value = clampedManevHUnits
    this.manevOnCallSliderTarget.value = onCallUnits
    // Set a high max initially so the slider can be moved freely
    this.manevOnCallSliderTarget.max = Math.max(maxOnCallUnits, 1000)

    // Recalculate everything
    this.updateAll()
  }

  adjustManevH() {
    if (!this.hasManevHSliderTarget || !this.hasManevOnCallSliderTarget) return

    // Prevent recursive updates
    if (this._adjusting) return
    this._adjusting = true

    try {
      const totalValue = this.getTotalValueInCents()

      if (totalValue <= 0) {
        this.resetAll()
        return
      }

      // OUT - MANEV-H is the PRIMARY value - get what user set
      let manevHUnits = parseInt(this.manevHSliderTarget.value) || 110
      const manevHAmount = manevHUnits * this.manevHUnitPriceValue

      // Clamp MANEV-H to valid range (110-176)
      if (manevHUnits < 110) {
        manevHUnits = 110
        this.manevHSliderTarget.value = manevHUnits
      } else if (manevHUnits > 176) {
        manevHUnits = 176
        this.manevHSliderTarget.value = manevHUnits
      }

      // Calculate remaining budget after MANEV-H
      const remainingBudget = totalValue - (manevHUnits * this.manevHUnitPriceValue)

      // Calculate ON-CALL units: floor(remaining / onCallUnitPrice)
      const onCallUnits = Math.floor(remainingBudget / this.manevOnCallUnitPriceValue)
      
      // Clamp to minimum 1
      const adjustedOnCallUnits = Math.max(1, onCallUnits)
      
      // Set the ON-CALL slider to the calculated value
      this.manevOnCallSliderTarget.value = adjustedOnCallUnits

      // Calculate max for ON-CALL (when MANEV-H is at minimum 110)
      const minManevHAmount = 110 * this.manevHUnitPriceValue
      const maxRemainingForOnCall = totalValue - minManevHAmount
      const maxOnCallUnits = Math.max(1, Math.floor(maxRemainingForOnCall / this.manevOnCallUnitPriceValue))
      
      // Update max for the slider
      this.manevOnCallSliderTarget.max = maxOnCallUnits

      this.updateAll()
    } finally {
      this._adjusting = false
    }
  }

  adjustManevOnCall() {
    if (!this.hasManevHSliderTarget || !this.hasManevOnCallSliderTarget) return

    // Prevent recursive updates
    if (this._adjusting) return
    this._adjusting = true

    try {
      const totalValue = this.getTotalValueInCents()

      if (totalValue <= 0) {
        this.resetAll()
        return
      }

      // OUT - MANEV-ON-CALL is the PRIMARY value - get what user set
      let onCallUnits = parseInt(this.manevOnCallSliderTarget.value) || 1
      const onCallAmount = onCallUnits * this.manevOnCallUnitPriceValue

      // Calculate max possible ON-CALL units (when MANEV-H is at minimum 110)
      const minManevHAmount = 110 * this.manevHUnitPriceValue
      const maxRemainingForOnCall = totalValue - minManevHAmount
      const maxOnCallUnits = Math.max(1, Math.floor(maxRemainingForOnCall / this.manevOnCallUnitPriceValue))

      // Clamp ON-CALL to max if it exceeds
      if (onCallUnits > maxOnCallUnits) {
        onCallUnits = maxOnCallUnits
        this.manevOnCallSliderTarget.value = onCallUnits
      }

      // Update max for the slider
      this.manevOnCallSliderTarget.max = maxOnCallUnits

      // Calculate remaining budget after ON-CALL
      const remainingBudget = totalValue - (onCallUnits * this.manevOnCallUnitPriceValue)

      // Calculate MANEV-H units: floor(remaining / manevHUnitPrice)
      const manevHUnits = Math.floor(remainingBudget / this.manevHUnitPriceValue)
      
      // Clamp to valid range (110-176)
      const adjustedManevHUnits = Math.max(110, Math.min(176, manevHUnits))
      
      // Set the MANEV-H slider to the calculated value
      this.manevHSliderTarget.value = adjustedManevHUnits

      this.updateAll()
    } finally {
      this._adjusting = false
    }
  }

  updateAll() {
    if (!this.hasValueInputTarget) return

    const totalValue = this.getTotalValueInCents()
    
    // Update total display first (always available)
    if (this.hasTotalDisplayTarget) {
      this.totalDisplayTarget.textContent = this.formatCurrency(totalValue / 100)
    }

    // If sliders don't exist, just show total
    if (!this.hasManevHSliderTarget || !this.hasManevOnCallSliderTarget) {
      return
    }

    const manevHUnits = parseInt(this.manevHSliderTarget.value) || 0
    const onCallUnits = parseInt(this.manevOnCallSliderTarget.value) || 0

    // Calculate amounts in cents
    const manevHAmount = manevHUnits * this.manevHUnitPriceValue
    const onCallAmount = onCallUnits * this.manevOnCallUnitPriceValue

    // Calculate token amount (difference)
    const tokenAmount = totalValue - manevHAmount - onCallAmount
    const tokenUnits = Math.max(0, Math.floor(tokenAmount / this.tokenUnitPriceValue))

    // Update displays (with safety checks)
    if (this.hasManevHDisplayTarget) {
      this.manevHDisplayTarget.textContent = manevHUnits.toString()
    }
    if (this.hasManevOnCallDisplayTarget) {
      this.manevOnCallDisplayTarget.textContent = onCallUnits.toString()
    }
    if (this.hasTokenDisplayTarget) {
      this.tokenDisplayTarget.textContent = tokenUnits.toString()
    }
    
    // Update token slider value (for visual feedback, even though disabled)
    if (this.hasTokenSliderTarget) {
      this.tokenSliderTarget.value = tokenUnits
    }

    // Update amount displays
    if (this.hasManevHAmountTarget) {
      this.manevHAmountTarget.textContent = this.formatCurrency(manevHAmount / 100)
    }
    if (this.hasManevOnCallAmountTarget) {
      this.manevOnCallAmountTarget.textContent = this.formatCurrency(onCallAmount / 100)
    }
    if (this.hasTokenAmountTarget) {
      this.tokenAmountTarget.textContent = this.formatCurrency(tokenAmount / 100)
    }

    // Update hidden fields for form submission
    if (this.hasManevHQuantityTarget) {
      this.manevHQuantityTarget.value = manevHUnits.toString()
    }
    if (this.hasManevHValueWithTaxTarget) {
      this.manevHValueWithTaxTarget.value = manevHAmount.toString()
    }
    if (this.hasManevOnCallQuantityTarget) {
      this.manevOnCallQuantityTarget.value = onCallUnits.toString()
    }
    if (this.hasManevOnCallValueWithTaxTarget) {
      this.manevOnCallValueWithTaxTarget.value = onCallAmount.toString()
    }
    if (this.hasTokenQuantityTarget) {
      this.tokenQuantityTarget.value = tokenUnits.toString()
    }
    if (this.hasTokenValueWithTaxTarget) {
      this.tokenValueWithTaxTarget.value = tokenAmount.toString()
    }

    // Update range slider visual feedback
    this.updateRangeSliderStyle(this.manevHSliderTarget, manevHUnits, 110, 176)
    this.updateRangeSliderStyle(this.manevOnCallSliderTarget, onCallUnits, 1, parseInt(this.manevOnCallSliderTarget.max) || 1000)
  }

  updateRangeSliderStyle(slider, value, min, max) {
    const percent = ((value - min) / (max - min)) * 100
    slider.style.setProperty("--value-percent", `${percent}%`)
  }

  resetAll() {
    if (this.hasManevHSliderTarget) {
      this.manevHSliderTarget.value = 110
    }
    if (this.hasManevOnCallSliderTarget) {
      this.manevOnCallSliderTarget.value = 1
    }
    if (this.hasTokenDisplayTarget) {
      this.tokenDisplayTarget.textContent = "0"
    }
    if (this.hasManevHDisplayTarget) {
      this.manevHDisplayTarget.textContent = "110"
    }
    if (this.hasManevOnCallDisplayTarget) {
      this.manevOnCallDisplayTarget.textContent = "1"
    }
    if (this.hasManevHAmountTarget) {
      this.manevHAmountTarget.textContent = "EUR 0.00"
    }
    if (this.hasManevOnCallAmountTarget) {
      this.manevOnCallAmountTarget.textContent = "EUR 0.00"
    }
    if (this.hasTokenAmountTarget) {
      this.tokenAmountTarget.textContent = "EUR 0.00"
    }
    if (this.hasTotalDisplayTarget) {
      this.totalDisplayTarget.textContent = "EUR 0.00"
    }
  }

  getTotalValueInCents() {
    const valueStr = this.valueInputTarget.value || "0"
    const valueInUnits = parseFloat(valueStr) || 0
    return Math.round(valueInUnits * 100) // Convert to cents
  }

  formatCurrency(value) {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "EUR",
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(value)
  }
}

