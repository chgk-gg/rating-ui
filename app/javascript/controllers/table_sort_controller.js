import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["header", "body"]
  static values = {
    column: { type: Number, default: -1 },
    direction: { type: String, default: "asc" }
  }

  sort(event) {
    const header = event.currentTarget
    const columnIndex = parseInt(header.dataset.sortColumn, 10)

    if (this.columnValue === columnIndex) {
      this.directionValue = this.directionValue === "asc" ? "desc" : "asc"
    } else {
      this.columnValue = columnIndex
      this.directionValue = "desc"
    }

    this.updateHeaderIndicators(header)
    this.sortTable(columnIndex, this.directionValue)
  }

  updateHeaderIndicators(activeHeader) {
    this.headerTargets.forEach(header => {
      const indicator = header.querySelector("[data-sort-indicator]")
      if (indicator) {
        if (header === activeHeader) {
          indicator.textContent = this.directionValue === "asc" ? "↑" : "↓"
        } else {
          indicator.textContent = ""
        }
      }
    })
  }

  sortTable(columnIndex, direction) {
    const tbody = this.bodyTarget
    const rows = Array.from(tbody.querySelectorAll("tr"))

    rows.sort((a, b) => {
      const aCell = a.children[columnIndex]
      const bCell = b.children[columnIndex]

      const aValue = this.getSortValue(aCell)
      const bValue = this.getSortValue(bCell)

      let comparison = 0
      if (aValue < bValue) comparison = -1
      if (aValue > bValue) comparison = 1

      return direction === "asc" ? comparison : -comparison
    })

    rows.forEach(row => tbody.appendChild(row))
  }

  getSortValue(cell) {
    const rawValue = cell.dataset.sortValue
    if (rawValue !== undefined) {
      const num = parseFloat(rawValue)
      return isNaN(num) ? 0 : num
    }
    const text = cell.textContent.trim()
    const num = parseFloat(text)
    return isNaN(num) ? 0 : num
  }
}
