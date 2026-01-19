import { Controller } from "@hotwired/stimulus"
import { Chart, ArcElement, DoughnutController, Tooltip, Legend } from "chart.js"

Chart.register(ArcElement, DoughnutController, Tooltip, Legend)

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    data: Array,
    filterUrl: String
  }

  connect() {
    this.renderChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }

  renderChart() {
    const ctx = this.canvasTarget.getContext("2d")
    const data = this.dataValue

    if (data.length === 0) {
      return
    }

    const labels = data.map(d => d.name)
    const values = data.map(d => Math.abs(d.amount))
    const colors = data.map(d => d.color)
    const categoryIds = data.map(d => d.id)

    this.chart = new Chart(ctx, {
      type: "doughnut",
      data: {
        labels: labels,
        datasets: [{
          data: values,
          backgroundColor: colors,
          borderColor: colors.map(c => this.adjustBrightness(c, -20)),
          borderWidth: 2,
          hoverOffset: 8
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        cutout: "60%",
        plugins: {
          legend: {
            display: false
          },
          tooltip: {
            callbacks: {
              label: (context) => {
                const value = context.raw
                const total = context.dataset.data.reduce((a, b) => a + b, 0)
                const percentage = ((value / total) * 100).toFixed(1)
                return `€${value.toLocaleString('de-DE', { minimumFractionDigits: 2 })} (${percentage}%)`
              }
            }
          }
        },
        onClick: (event, elements) => {
          if (elements.length > 0) {
            const index = elements[0].index
            const categoryId = categoryIds[index]
            this.filterByCategory(categoryId)
          }
        },
        onHover: (event, elements) => {
          event.native.target.style.cursor = elements.length > 0 ? 'pointer' : 'default'
        }
      }
    })
  }

  filterByCategory(categoryId) {
    const url = new URL(this.filterUrlValue, window.location.origin)
    if (categoryId === "uncategorized") {
      url.searchParams.set("category_id", "uncategorized")
    } else if (categoryId) {
      url.searchParams.set("category_id", categoryId)
    }
    
    Turbo.visit(url.toString())
  }

  adjustBrightness(hex, percent) {
    const num = parseInt(hex.replace("#", ""), 16)
    const amt = Math.round(2.55 * percent)
    const R = Math.max(0, Math.min(255, (num >> 16) + amt))
    const G = Math.max(0, Math.min(255, ((num >> 8) & 0x00FF) + amt))
    const B = Math.max(0, Math.min(255, (num & 0x0000FF) + amt))
    return `#${(0x1000000 + R * 0x10000 + G * 0x100 + B).toString(16).slice(1)}`
  }
}
