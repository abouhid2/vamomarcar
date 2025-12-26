import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "day",
    "addButton",
    "form",
    "startDateInput",
    "endDateInput",
    "selectionText",
    "submitButton",
    "clearButton",
    "removeButton",
    "modal",
    "yearSelect",
    "holidaysList",
    "loading",
    "confirmButton",
    "holidayItemTemplate"
  ]

  static values = {
    selectedSingle: String,
    selectedRange: String,
    selectPrompt: String,
    holidaySelectYear: String,
    holidayError: String,
    holidayNoHolidays: String,
    holidayCountTitle: String,
    holidayCountSubtitle: String,
    holidayErrorAdding: String,
    locale: String
  }

  connect() {
    console.log("Calendar controller connected!")
    this.isSelecting = false
    this.selectionStart = null
    this.selectionEnd = null
    this.selectedDates = []

    // Add mouseup listener to document to catch mouseup outside calendar
    this.handleMouseUp = this.endSelection.bind(this)
    document.addEventListener("mouseup", this.handleMouseUp)

    // Update the current month in the form on initial load
    this.updateCurrentMonthField()
  }

  updateCurrentMonth() {
    // Called when turbo frame loads (calendar navigation)
    this.updateCurrentMonthField()
  }

  updateCurrentMonthField() {
    // Find the calendar element inside the turbo frame
    const calendarElement = document.querySelector('[data-current-month]')
    if (!calendarElement) return

    const currentMonth = calendarElement.dataset.currentMonth
    if (!currentMonth) return

    // Update the hidden field in the form
    const currentMonthInput = this.element.querySelector('[name="current_month"]')
    if (currentMonthInput) {
      currentMonthInput.value = currentMonth
    }
  }

  disconnect() {
    // Clean up event listener
    document.removeEventListener("mouseup", this.handleMouseUp)
  }

  startSelection(event) {
    const dayCell = event.currentTarget
    const date = dayCell.dataset.date
    const disabled = dayCell.dataset.disabled === "true"

    // Don't start selection on disabled days
    if (disabled) {
      return
    }

    // Prevent text selection during drag
    event.preventDefault()

    this.isSelecting = true
    this.selectionStart = date
    this.selectionEnd = date

    this.updateSelection()
  }

  continueSelection(event) {
    if (!this.isSelecting) {
      return
    }

    const dayCell = event.currentTarget
    const date = dayCell.dataset.date
    const disabled = dayCell.dataset.disabled === "true"

    // Don't extend to disabled days
    if (disabled) {
      return
    }

    this.selectionEnd = date
    this.updateSelection()
  }

  endSelection() {
    if (!this.isSelecting) {
      return
    }

    this.isSelecting = false

    // If we have a valid selection, show the add button
    if (this.selectionStart && this.selectionEnd) {
      this.showAddButton()
    }
  }

  updateSelection() {
    // Clear all previous selection styling
    this.dayTargets.forEach(day => {
      day.classList.remove("bg-teal-100", "border-teal-300", "ring-2", "ring-teal-400")
    })

    // Get range of dates
    const startDate = new Date(this.selectionStart)
    const endDate = new Date(this.selectionEnd)

    // Ensure start is before end
    const [minDate, maxDate] = startDate <= endDate
      ? [startDate, endDate]
      : [endDate, startDate]

    // Find all days in range and apply selection styling
    this.selectedDates = []
    this.dayTargets.forEach(day => {
      const dayDate = new Date(day.dataset.date)
      const disabled = day.dataset.disabled === "true"

      if (!disabled && dayDate >= minDate && dayDate <= maxDate) {
        day.classList.add("bg-teal-100", "border-teal-300", "ring-2", "ring-teal-400")
        this.selectedDates.push(day.dataset.date)
      }
    })
  }

  showAddButton() {
    if (this.selectedDates.length === 0) {
      return
    }

    // Sort dates
    this.selectedDates.sort()

    // Get start and end dates
    const startDate = this.selectedDates[0]
    const endDate = this.selectedDates[this.selectedDates.length - 1]

    // Update hidden form fields
    this.startDateInputTarget.value = startDate
    this.endDateInputTarget.value = endDate

    // Update selection text with translations
    const startFormatted = this.formatDate(new Date(startDate))
    const endFormatted = this.formatDate(new Date(endDate))

    if (startDate === endDate) {
      this.selectionTextTarget.textContent = this.selectedSingleValue.replace('%{date}', startFormatted)
    } else {
      this.selectionTextTarget.textContent = this.selectedRangeValue
        .replace('%{start}', startFormatted)
        .replace('%{end}', endFormatted)
        .replace('%{count}', this.selectedDates.length)
    }

    // Enable submit and remove buttons, show clear button
    this.submitButtonTarget.disabled = false
    this.removeButtonTarget.disabled = false
    this.clearButtonTarget.classList.remove("hidden")
  }

  selectWholeMonth() {
    // Clear any existing selection first
    this.dayTargets.forEach(day => {
      day.classList.remove("bg-teal-100", "border-teal-300", "ring-2", "ring-teal-400")
    })

    // Find all valid (non-disabled, in-month) days
    const validDays = this.dayTargets.filter(day => {
      const disabled = day.dataset.disabled === "true"
      const inMonth = !day.classList.contains("opacity-40")
      return !disabled && inMonth
    })

    if (validDays.length === 0) {
      return
    }

    // Select all valid days
    this.selectedDates = []
    validDays.forEach(day => {
      day.classList.add("bg-teal-100", "border-teal-300", "ring-2", "ring-teal-400")
      this.selectedDates.push(day.dataset.date)
    })

    // Sort dates to get start and end
    this.selectedDates.sort()
    const startDate = this.selectedDates[0]
    const endDate = this.selectedDates[this.selectedDates.length - 1]

    // Update form fields
    this.startDateInputTarget.value = startDate
    this.endDateInputTarget.value = endDate

    // Update selection text with translations
    const startFormatted = this.formatDate(new Date(startDate))
    const endFormatted = this.formatDate(new Date(endDate))
    this.selectionTextTarget.textContent = this.selectedRangeValue
      .replace('%{start}', startFormatted)
      .replace('%{end}', endFormatted)
      .replace('%{count}', this.selectedDates.length)

    // Enable submit and remove buttons, show clear button
    this.submitButtonTarget.disabled = false
    this.removeButtonTarget.disabled = false
    this.clearButtonTarget.classList.remove("hidden")
  }

  selectAllHolidays() {
    // Open the modal
    this.openModal()
    // Load holidays for the current year (after DOM updates)
    setTimeout(() => {
      this.loadHolidays()
    }, 10)
  }

  openModal() {
    this.modalTarget.classList.remove("hidden")
  }

  closeModal() {
    this.modalTarget.classList.add("hidden")
    // Reset the modal state with translated text
    this.holidaysListTarget.innerHTML = `<div class="text-center text-gray-500 py-8">${this.holidaySelectYearValue}</div>`
    this.confirmButtonTarget.disabled = true
  }

  closeModalBackdrop(event) {
    // Only close if clicking the backdrop itself
    if (event.target === event.currentTarget) {
      this.closeModal()
    }
  }

  stopPropagation(event) {
    // Prevent clicks inside the modal from closing it
    event.stopPropagation()
  }

  loadHolidays() {
    const year = this.yearSelectTarget.value
    const formAction = this.formTarget.action
    const groupId = formAction.match(/groups\/(\d+)/)[1]

    // Show loading state
    this.loadingTarget.classList.remove("hidden")
    this.holidaysListTarget.classList.add("hidden")

    // Fetch holidays from the server
    fetch(`/groups/${groupId}/availabilities/preview_holidays?year=${year}`, {
      headers: {
        'Accept': 'application/json'
      }
    })
      .then(response => response.json())
      .then(data => {
        this.displayHolidays(data)
        this.loadingTarget.classList.add("hidden")
        this.holidaysListTarget.classList.remove("hidden")
        this.confirmButtonTarget.disabled = false
      })
      .catch(error => {
        console.error('Error loading holidays:', error)
        this.loadingTarget.classList.add("hidden")
        this.holidaysListTarget.innerHTML = `<div class="text-center text-red-500 py-8">${this.holidayErrorValue}</div>`
        this.holidaysListTarget.classList.remove("hidden")
      })
  }

  displayHolidays(data) {
    if (data.count === 0) {
      this.holidaysListTarget.innerHTML = `<div class="text-center text-gray-500 py-8">${this.holidayNoHolidaysValue}</div>`
      this.confirmButtonTarget.disabled = true
      return
    }

    // Create header section
    const header = document.createElement('div')
    header.className = 'mb-4 p-4 bg-purple-50 rounded-lg'

    const title = document.createElement('p')
    title.className = 'text-lg font-semibold text-purple-900'
    title.textContent = this.holidayCountTitleValue
      .replace('%{count}', data.count)
      .replace('%{year}', data.year)

    const subtitle = document.createElement('p')
    subtitle.className = 'text-sm text-purple-700 mt-1'
    subtitle.textContent = this.holidayCountSubtitleValue

    header.appendChild(title)
    header.appendChild(subtitle)

    // Create container for holiday items
    const container = document.createElement('div')
    container.className = 'space-y-2'

    // Add each holiday using the template
    data.holidays.forEach(holiday => {
      const clone = this.holidayItemTemplateTarget.content.cloneNode(true)

      const nameElement = clone.querySelector('[data-holiday-name]')
      const dayElement = clone.querySelector('[data-holiday-day]')
      const dateElement = clone.querySelector('[data-holiday-date]')

      nameElement.textContent = holiday.name
      dayElement.textContent = holiday.day_of_week
      dateElement.textContent = holiday.date

      container.appendChild(clone)
    })

    // Clear and update the holidays list
    this.holidaysListTarget.innerHTML = ''
    this.holidaysListTarget.appendChild(header)
    this.holidaysListTarget.appendChild(container)
  }

  confirmAddHolidays() {
    const year = this.yearSelectTarget.value
    const formAction = this.formTarget.action
    const groupId = formAction.match(/groups\/(\d+)/)[1]

    // Get the current month for the return month
    const currentMonthInput = this.formTarget.querySelector('[name="current_month"]')
    const currentMonth = currentMonthInput ? currentMonthInput.value : ''

    // Build the URL for the add_all_holidays endpoint
    const url = `/groups/${groupId}/availabilities/add_all_holidays`

    // Create form data
    const formData = new FormData()
    formData.append('year', year)
    formData.append('current_month', currentMonth)

    // Submit the request
    fetch(url, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        'Accept': 'text/vnd.turbo-stream.html'
      },
      body: formData
    }).then(response => {
      if (response.ok) {
        return response.text()
      } else {
        console.error('Failed to add holidays')
        throw new Error('Failed to add holidays')
      }
    }).then(html => {
      // Process the Turbo Stream response
      Turbo.renderStreamMessage(html)
      // Close the modal
      this.closeModal()
    }).catch(error => {
      console.error('Error adding holidays:', error)
      alert(this.holidayErrorAddingValue)
    })
  }

  removeAvailability() {
    if (this.selectedDates.length === 0) {
      return
    }

    const startDate = this.startDateInputTarget.value
    const endDate = this.endDateInputTarget.value

    if (!startDate || !endDate) {
      return
    }

    // Get the group ID from the form action URL
    const formAction = this.formTarget.action
    const groupId = formAction.match(/groups\/(\d+)/)[1]

    // Build the URL for the remove endpoint
    const url = `/groups/${groupId}/availabilities/remove_range`

    // Get the current month for the redirect
    const currentMonthInput = this.formTarget.querySelector('[name="current_month"]')
    const currentMonth = currentMonthInput ? currentMonthInput.value : ''

    // Create form data
    const formData = new FormData()
    formData.append('start_date', startDate)
    formData.append('end_date', endDate)
    formData.append('current_month', currentMonth)

    // Submit the request
    fetch(url, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
        'Accept': 'text/vnd.turbo-stream.html'
      },
      body: formData
    }).then(response => {
      if (response.ok) {
        return response.text()
      } else {
        console.error('Failed to remove availability')
        throw new Error('Failed to remove availability')
      }
    }).then(html => {
      // Process the Turbo Stream response
      Turbo.renderStreamMessage(html)
      // Clear the selection after successful removal
      this.clearSelection()
    }).catch(error => {
      console.error('Error removing availability:', error)
    })
  }

  clearSelection() {
    // Clear visual selection
    this.dayTargets.forEach(day => {
      day.classList.remove("bg-teal-100", "border-teal-300", "ring-2", "ring-teal-400")
    })

    // Reset state
    this.isSelecting = false
    this.selectionStart = null
    this.selectionEnd = null
    this.selectedDates = []

    // Disable submit and remove buttons, hide clear button
    this.submitButtonTarget.disabled = true
    this.removeButtonTarget.disabled = true
    this.clearButtonTarget.classList.add("hidden")

    // Reset selection text with translated prompt
    this.selectionTextTarget.textContent = this.selectPromptValue

    // Clear form fields
    this.startDateInputTarget.value = ""
    this.endDateInputTarget.value = ""
  }

  formatDate(date) {
    const locale = this.localeValue || 'pt-BR'
    const options = { year: 'numeric', month: 'long', day: 'numeric' }
    return date.toLocaleDateString(locale, options)
  }

  // This will be called automatically when form is submitted via Turbo
  // The form submission will trigger the create action in AvailabilitiesController
}
