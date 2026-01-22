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
    const textColor = isDarkMode ? 'rgb(255, 255, 255)' : 'rgb(0, 0, 0)'

    this.chart = new Chart(ctx, {
      type: "bar",
      data: {
        labels: data.labels,
        datasets: [
          {
            label: "Unpaid",
            data: data.unpaid,
            backgroundColor: "rgba(239, 68, 68, 0.7)", // red-500
            borderColor: "rgb(239, 68, 68)",
            borderWidth: 1,
            borderRadius: 4
          },
          {
            label: "Paid",
            data: data.paid,
            backgroundColor: "rgba(34, 197, 94, 0.7)", // green-500
            borderColor: "rgb(34, 197, 94)",
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
              padding: 15
            }
          },
          tooltip: {
            backgroundColor: isDarkMode ? 'rgba(0, 0, 0, 0.8)' : 'rgba(255, 255, 255, 0.95)',
            titleColor: textColor,
            bodyColor: textColor,
            borderColor: isDarkMode ? 'rgba(255, 255, 255, 0.2)' : 'rgba(0, 0, 0, 0.2)',
            borderWidth: 1,
            callbacks: {
              label: (context) => {
                const value = context.raw
                if (value === 0) return null
                return `${context.dataset.label}: €${value.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
              },
              footer: (tooltipItems) => {
                const total = tooltipItems.reduce((sum, item) => sum + (item.raw || 0), 0)
                if (total === 0) return null
                return `Total: €${total.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
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
            },
            title: {
              display: false
            }
          },
          y: {
            beginAtZero: true,
            grid: {
              color: gridColor
            },
            ticks: {
              color: textColor,
              callback: (value) => {
                if (value === 0) return "€0"
                return `€${value.toLocaleString('en-US')}`
              }
            },
            title: {
              display: false
            }
          }
        }
      }
    })
  }
}
