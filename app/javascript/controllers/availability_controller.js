import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["template", "container"]

  addDateRange(event) {
    event.preventDefault()
    const content = this.templateTarget.innerHTML
    this.containerTarget.insertAdjacentHTML('beforeend', content)
  }

  removeRow(event) {
    event.preventDefault()
    const row = event.target.closest('.date-range-row')
    row.remove()
  }

  selectMonth(event) {
    event.preventDefault()
    const button = event.target
    const monthOffset = parseInt(button.dataset.month)
    const year = parseInt(button.dataset.year)
    const month = parseInt(button.dataset.monthNumber)

    const startDate = new Date(year, month - 1, 1)
    const endDate = new Date(year, month, 0)

    const startInput = document.querySelector('[name="availability[start_date]"]')
    const endInput = document.querySelector('[name="availability[end_date]"]')

    if (startInput && endInput) {
      startInput.value = this.formatDate(startDate)
      endInput.value = this.formatDate(endDate)

      // Visual feedback
      this.flashInputs([startInput, endInput])
      this.flashButton(button)
    }
  }

  flashInputs(inputs) {
    inputs.forEach(input => {
      input.classList.add('ring-4', 'ring-green-300')
      setTimeout(() => {
        input.classList.remove('ring-4', 'ring-green-300')
      }, 1000)
    })
  }

  flashButton(button) {
    const originalClasses = button.className
    button.classList.add('bg-green-500', 'text-white', 'border-green-500')
    setTimeout(() => {
      button.className = originalClasses
    }, 500)
  }

  formatDate(date) {
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    return `${year}-${month}-${day}`
  }

  syncEndDate(event) {
    const startInput = event.target
    const endInput = this.element.querySelector('[data-availability-target="endDate"]')

    if (endInput && (!endInput.value || endInput.value < startInput.value)) {
      endInput.value = startInput.value
    }
  }

  connect() {
    console.log("Availability controller connected!")
  }
}
