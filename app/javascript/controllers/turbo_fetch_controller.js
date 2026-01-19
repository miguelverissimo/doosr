import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String
  }

  async load(event) {
    if (event) event.preventDefault()

    try {
      const response = await fetch(this.urlValue, {
        headers: {
          "Accept": "text/vnd.turbo-stream.html"
        }
      })

      if (response.ok) {
        const html = await response.text()

        // Parse the turbo stream response and execute actions manually
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, "text/html")
        const streams = doc.querySelectorAll("turbo-stream")

        streams.forEach(stream => {
          const action = stream.getAttribute("action")
          const target = stream.getAttribute("target")
          const template = stream.querySelector("template")

          if (template && target) {
            const targetElement = document.getElementById(target)
            if (targetElement) {
              if (action === "replace") {
                targetElement.replaceWith(template.content.cloneNode(true))
              } else if (action === "append") {
                targetElement.appendChild(template.content.cloneNode(true))
              } else if (action === "prepend") {
                targetElement.prepend(template.content.cloneNode(true))
              } else if (action === "remove") {
                targetElement.remove()
              }
            }
          }
        })
      }
    } catch (error) {
      console.error("Error fetching turbo stream:", error)
    }
  }
}
