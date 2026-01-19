import { Controller } from "@hotwired/stimulus"
import { Chart, BarElement, BarController, CategoryScale, LinearScale, Tooltip, Legend } from "chart.js"

Chart.register(BarElement, BarController, CategoryScale, LinearScale, Tooltip, Legend)

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    data: Object
  }

  connect() {
    console.log("[spending-chart] Controller connected")
    this.renderChart()
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }

  renderChart() {
    console.log("[spending-chart] Rendering chart, data:", this.dataValue)
    const ctx = this.canvasTarget.getContext("2d")
    const data = this.dataValue

    if (!data.labels || data.labels.length === 0) {
      console.log("[spending-chart] No labels, skipping render")
      return
    }
    console.log("[spending-chart] Labels count:", data.labels.length)

    const isDarkMode = document.documentElement.classList.contains('dark')
    const gridColor = isDarkMode ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)'
    const textColor = isDarkMode ? 'rgba(255, 255, 255, 0.7)' : 'rgba(0, 0, 0, 0.7)'

    this.chart = new Chart(ctx, {
      type: "bar",
      data: {
        labels: data.labels,
        datasets: [
          {
            label: "Income",
            data: data.income,
            backgroundColor: "rgba(34, 197, 94, 0.7)",
            borderColor: "rgb(34, 197, 94)",
            borderWidth: 1,
            borderRadius: 4
          },
          {
            label: "Expenses",
            data: data.expenses,
            backgroundColor: "rgba(239, 68, 68, 0.7)",
            borderColor: "rgb(239, 68, 68)",
            borderWidth: 1,
            borderRadius: 4
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          intersect: false,
          mode: "index"
        },
        plugins: {
          legend: {
            position: "top",
            labels: {
              color: textColor,
              usePointStyle: true,
              padding: 20
            }
          },
          tooltip: {
            callbacks: {
              label: (context) => {
                const value = context.raw
                return `${context.dataset.label}: €${value.toLocaleString('de-DE', { minimumFractionDigits: 2 })}`
              }
            }
          }
        },
        scales: {
          x: {
            grid: {
              display: false
            },
            ticks: {
              color: textColor
            }
          },
          y: {
            beginAtZero: true,
            grid: {
              color: gridColor
            },
            ticks: {
              color: textColor,
              callback: (value) => `€${value.toLocaleString('de-DE')}`
            }
          }
        }
      }
    })
  }
}
