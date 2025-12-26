import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "removeButton", "form"]
  static values = {
    confirmMessage: String,
    entries: Object
  }

  connect() {
    this.updateRemoveButton()
  }

  toggleSelection(event) {
    // Enable/disable corresponding hidden field
    const batchFieldId = event.target.dataset.batchField
    const hiddenField = document.getElementById(batchFieldId)
    if (hiddenField) {
      hiddenField.disabled = !event.target.checked
    }
    this.updateRemoveButton()
  }

  updateRemoveButton() {
    const anyChecked = this.checkboxTargets.some(checkbox => checkbox.checked)
    this.removeButtonTarget.classList.toggle("hidden", !anyChecked)
  }

  submitBatch(event) {
    event.preventDefault()

    const checkedCount = this.checkboxTargets.filter(cb => cb.checked).length

    if (checkedCount === 0) {
      return
    }

    // Get the appropriate entries translation (singular/plural)
    const entriesText = checkedCount === 1 ? this.entriesValue.one : this.entriesValue.other
    const message = this.confirmMessageValue
      .replace('%{count}', checkedCount)
      .replace('%{entries}', entriesText)

    if (!confirm(message)) {
      return
    }

    // Submit the form with the selected IDs
    this.formTarget.submit()
  }
}
