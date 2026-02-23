import { Controller } from "@hotwired/stimulus"
import { Chart, BarElement, BarController, CategoryScale, LinearScale, Tooltip, Legend } from "chart.js"

Chart.register(BarElement, BarController, CategoryScale, LinearScale, Tooltip, Legend)

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    data: Object
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

    if (!data.labels || data.labels.length === 0) {
      return
    }

    const isDarkMode = document.documentElement.classList.contains('dark')
    const gridColor = isDarkMode ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)'
    const textColor = isDarkMode ? 'rgba(255, 255, 255, 0.7)' : 'rgba(0, 0, 0, 0.7)'

    this.chart = new Chart(ctx, {
      type: "bar",
      data: {
        labels: data.labels,
        datasets: [
          {
            label: "Transfers",
            data: data.transfers,
            backgroundColor: "rgba(147, 51, 234, 0.7)",
            borderColor: "rgb(147, 51, 234)",
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
