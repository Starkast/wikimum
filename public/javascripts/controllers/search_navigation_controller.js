import {Controller} from "@hotwired/stimulus"
import * as Turbo from "@hotwired/turbo"

export default class extends Controller {
  connect() {
    let selectedLink = this.#getSelectedElement();
    if (!selectedLink) {
      let pageLinks = document.getElementsByClassName('page-link');
      if (pageLinks && pageLinks.length > 0) {
        this.#selectElement(pageLinks[0]);
      }
    }
  }

  down() {
    let selectedLink = this.#getSelectedElement();
    if (selectedLink) {
      let pageLinks = document.getElementsByClassName('page-link');

      for (let i = 0; i < pageLinks.length; i++) {
        let page = pageLinks[i];
        if (page === selectedLink && i < (pageLinks.length - 1)) {
          this.#selectElement(pageLinks[i + 1])
          this.#deselectElement(pageLinks[i]);
          break;
        }
      }
      return false;
    }
  }

  up() {
    let selectedLink = this.#getSelectedElement();
    if (selectedLink) {
      let pageLinks = document.getElementsByClassName('page-link');

      for (let i = 0; i < pageLinks.length; i++) {
        let page = pageLinks[i];
        if (page === selectedLink && i > 0) {
          this.#selectElement(pageLinks[i - 1])
          this.#deselectElement(pageLinks[i]);
          break;
        }
      }
      return false;
    }
  }

  open() {
    let selectedLink = this.#getSelectedElement();
    if (selectedLink) {
      selectedLink.click()
      return false;
    }
  }

  #getSelectedElement() {
    return document.getElementById('navigation-selected');
  }

  #selectElement(element) {
    element.id = "navigation-selected";
    return true;
  }

  #deselectElement(element) {
    element.id = "";
    return true;
  }

  #isInputField(target) {
    let targetTag = target.tagName.toLowerCase()
    return targetTag !== 'input' && targetTag !== 'textarea' && targetTag !== 'select'
  }
}
