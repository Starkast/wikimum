import {Controller} from "@hotwired/stimulus"
import * as Turbo from "@hotwired/turbo"

export default class extends Controller {
  home(event) {
    if (this.#isInputField(event.target)) {
      Turbo.visit("/")
    }
  }

  list(event) {
    if (this.#isInputField(event.target)) {
      Turbo.visit("/list")
    }
  }

  latest(event) {
    if (this.#isInputField(event.target)) {
      Turbo.visit("/latest")
    }
  }

  new(event) {
    if (this.#isInputField(event.target)) {
      Turbo.visit("/new")
    }
  }

  edit(event) {
    if (this.#isInputField(event.target)) {
      let editPageLink = document.querySelector("#edit_page")
      if (editPageLink) {
        Turbo.visit(editPageLink.href)
      }
    }
  }

  focusSearch(event) {
    if (this.#isInputField(event.target)) {
      let searchInput = document.getElementById('q')
      searchInput.focus()
      searchInput.select()
      event.preventDefault()
    }
  }

  blurSearch(event) {
    let searchInput = document.getElementById('q');
    if (event.target === searchInput) {
      searchInput.blur();
    }
    event.preventDefault()
  }

  #isInputField(target) {
    let targetTag = target.tagName.toLowerCase()
    return targetTag !== 'input' && targetTag !== 'textarea' && targetTag !== 'select'
  }
}
