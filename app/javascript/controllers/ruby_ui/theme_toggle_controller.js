import { Controller } from "@hotwired/stimulus";

const THEME_KEY = "theme";
const THEME_DARK = "dark";
const THEME_LIGHT = "light";

export default class extends Controller {
  connect() {
    this.#initializeTheme();
    this.#listenToSystemPreference();
  }

  toggle() {
    const currentTheme = this.#getStoredTheme();
    const newTheme = currentTheme === THEME_DARK ? THEME_LIGHT : THEME_DARK;
    this.#setTheme(newTheme);
  }

  #initializeTheme() {
    const storedTheme = this.#getStoredTheme();
    if (storedTheme) {
      this.#applyTheme(storedTheme);
    } else {
      // System default - check system preference
      const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
      this.#applyTheme(prefersDark ? THEME_DARK : THEME_LIGHT);
    }
  }

  #listenToSystemPreference() {
    // Only listen if user hasn't set a preference
    if (!this.#getStoredTheme()) {
      window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", (e) => {
        this.#applyTheme(e.matches ? THEME_DARK : THEME_LIGHT);
      });
    }
  }

  #getStoredTheme() {
    return localStorage.getItem(THEME_KEY);
  }

  #setTheme(theme) {
    localStorage.setItem(THEME_KEY, theme);
    this.#applyTheme(theme);
  }

  #applyTheme(theme) {
    if (theme === THEME_DARK) {
      document.documentElement.classList.add("dark");
    } else {
      document.documentElement.classList.remove("dark");
    }
  }
}

