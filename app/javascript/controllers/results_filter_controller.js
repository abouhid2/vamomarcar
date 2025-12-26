import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["resultItem", "allButton", "weekendsButton", "holidaysButton", "weekdaysButton", "dayButton", "count"]

  connect() {
    console.log("Results filter controller connected!")
  }

  showAll() {
    this.resultItemTargets.forEach(item => {
      item.classList.remove("hidden")
    })
    this.setActiveButton(this.allButtonTarget)
    this.updateCount()
  }

  showWeekendsOnly() {
    this.resultItemTargets.forEach(item => {
      const isWeekend = item.dataset.isWeekend === "true"
      if (isWeekend) {
        item.classList.remove("hidden")
      } else {
        item.classList.add("hidden")
      }
    })
    this.setActiveButton(this.weekendsButtonTarget)
    this.updateCount()
  }

  showHolidaysOnly() {
    this.resultItemTargets.forEach(item => {
      const isHoliday = item.dataset.isHoliday === "true"
      if (isHoliday) {
        item.classList.remove("hidden")
      } else {
        item.classList.add("hidden")
      }
    })
    this.setActiveButton(this.holidaysButtonTarget)
    this.updateCount()
  }

  showWeekdaysOnly() {
    this.resultItemTargets.forEach(item => {
      const isWeekend = item.dataset.isWeekend === "true"
      if (!isWeekend) {
        item.classList.remove("hidden")
      } else {
        item.classList.add("hidden")
      }
    })
    this.setActiveButton(this.weekdaysButtonTarget)
    this.updateCount()
  }

  showDay(event) {
    const targetDay = event.currentTarget.dataset.day
    this.resultItemTargets.forEach(item => {
      const dayOfWeek = item.dataset.dayOfWeek
      if (dayOfWeek === targetDay) {
        item.classList.remove("hidden")
      } else {
        item.classList.add("hidden")
      }
    })
    this.setActiveButton(event.currentTarget)
    this.updateCount()
  }

  updateCount() {
    const visibleCount = this.resultItemTargets.filter(item => !item.classList.contains("hidden")).length
    if (this.hasCountTarget) {
      this.countTarget.textContent = `(${visibleCount} dates)`
    }
  }

  setActiveButton(activeButton) {
    // Remove active state from all filter buttons
    const allFilterButtons = [
      this.allButtonTarget,
      this.weekendsButtonTarget,
      this.holidaysButtonTarget,
      this.weekdaysButtonTarget,
      ...this.dayButtonTargets
    ]

    allFilterButtons.forEach(button => {
      button.classList.remove("bg-teal-600", "text-white")
      button.classList.add("bg-gray-200", "text-gray-700", "hover:bg-gray-300")
    })

    // Add active state to the clicked button
    activeButton.classList.remove("bg-gray-200", "text-gray-700", "hover:bg-gray-300")
    activeButton.classList.add("bg-teal-600", "text-white")
  }
}
