import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "inviteUrl"]

  connect() {
    // Initialize clipboard API availability
    this.clipboardAvailable = !!navigator.clipboard
  }

  openModal(event) {
    event.preventDefault()
    const url = event.currentTarget.dataset.shareUrl

    // Fetch the share modal content via AJAX
    fetch(url)
      .then(response => response.text())
      .then(html => {
        // Insert modal into DOM
        document.body.insertAdjacentHTML('beforeend', html)

        // Show modal
        const modal = document.getElementById('shareInviteModal')
        modal.classList.remove('hidden')

        // Setup close handlers
        this.setupModalHandlers(modal)
      })
      .catch(error => console.error('Error loading share modal:', error))
  }

  setupModalHandlers(modal) {
    // Close on backdrop click
    modal.addEventListener('click', (e) => {
      if (e.target === modal) {
        this.closeModal(modal)
      }
    })

    // Close on ESC key
    const escHandler = (e) => {
      if (e.key === 'Escape') {
        this.closeModal(modal)
        document.removeEventListener('keydown', escHandler)
      }
    }
    document.addEventListener('keydown', escHandler)
  }

  closeModal(event) {
    // If called from event handler, get the modal from DOM
    // If called directly with modal element, use it
    const modalElement = event instanceof Event ?
      document.getElementById('shareInviteModal') :
      event

    if (modalElement) {
      modalElement.classList.add('hidden')
      setTimeout(() => modalElement.remove(), 300) // Remove after transition
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  copyToClipboard(event) {
    const url = event.currentTarget.dataset.url
    const button = event.currentTarget

    if (this.clipboardAvailable) {
      navigator.clipboard.writeText(url).then(() => {
        this.showCopyFeedback(button)
      }).catch(err => {
        console.error('Failed to copy:', err)
        this.fallbackCopy(url, button)
      })
    } else {
      this.fallbackCopy(url, button)
    }
  }

  fallbackCopy(text, button) {
    // Fallback for older browsers
    const textarea = document.createElement('textarea')
    textarea.value = text
    textarea.style.position = 'fixed'
    textarea.style.opacity = '0'
    document.body.appendChild(textarea)
    textarea.select()

    try {
      document.execCommand('copy')
      this.showCopyFeedback(button)
    } catch (err) {
      console.error('Fallback copy failed:', err)
    }

    document.body.removeChild(textarea)
  }

  showCopyFeedback(button) {
    const originalText = button.innerHTML
    button.innerHTML = `
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
      </svg>
      <span>Copied!</span>
    `
    button.classList.add('bg-green-600', 'hover:bg-green-700')
    button.classList.remove('bg-teal-600', 'hover:bg-teal-700')

    setTimeout(() => {
      button.innerHTML = originalText
      button.classList.remove('bg-green-600', 'hover:bg-green-700')
      button.classList.add('bg-teal-600', 'hover:bg-teal-700')
    }, 2000)
  }

  shareWhatsApp(event) {
    const url = event.currentTarget.dataset.url
    const text = event.currentTarget.dataset.text || 'Join my group on Bora Marcar!'
    const whatsappUrl = `https://wa.me/?text=${encodeURIComponent(text + ' ' + url)}`
    window.open(whatsappUrl, '_blank', 'noopener,noreferrer')
  }

  shareInstagram(event) {
    // Instagram doesn't support direct link sharing via URL
    // Copy to clipboard and show instruction
    const url = event.currentTarget.dataset.url

    if (this.clipboardAvailable) {
      navigator.clipboard.writeText(url).then(() => {
        alert('Link copied! Open Instagram and paste it in your DM or story.')
      })
    } else {
      this.fallbackCopy(url, event.currentTarget)
      alert('Link copied! Open Instagram and paste it in your DM or story.')
    }
  }

  disconnect() {
    // Cleanup if modal is still open
    const modal = document.getElementById('shareInviteModal')
    if (modal) {
      modal.remove()
    }
  }
}
