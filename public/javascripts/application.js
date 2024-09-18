import { Application } from "@hotwired/stimulus"
import "@hotwired/turbo"

import PageNavigationController from "controllers/page_navigation_controller"
import SearchNavigationController from "controllers/search_navigation_controller"

window.Stimulus = Application.start()
Stimulus.register("page-navigation", PageNavigationController)
Stimulus.register("search-navigation", SearchNavigationController)
