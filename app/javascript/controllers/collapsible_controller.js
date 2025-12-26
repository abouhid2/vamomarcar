import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "icon"]

  connect() {
    // Start expanded by default
    this.isOpen = true
  }

  toggle() {
    this.isOpen = !this.isOpen

    if (this.isOpen) {
      this.contentTarget.classList.remove("hidden")
      this.iconTarget.classList.remove("rotate-180")
    } else {
      this.contentTarget.classList.add("hidden")
      this.iconTarget.classList.add("rotate-180")
    }
  }
}
