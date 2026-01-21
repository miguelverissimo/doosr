import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["chart"]
  static values = {
    projections: Array
  }

  connect() {
    this.renderChart()
  }

  renderChart() {
    // The chart is rendered server-side as a fallback
    // This controller can be extended to use Chart.js or similar
    // for more interactive charts if needed
    if (this.hasChartTarget && this.projectionsValue.length > 0) {
      this.addTooltips()
    }
  }

  addTooltips() {
    const bars = this.chartTarget.querySelectorAll('[title]')
    bars.forEach(bar => {
      bar.classList.add('cursor-pointer', 'transition-opacity', 'hover:opacity-80')
    })
  }
}
