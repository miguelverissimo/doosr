import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  openRecovery(event) {
    event.preventDefault()
    
    console.log('[settings-recovery] Opening recovery in settings')
    
    // Wait for unlock dialog to be dismissed
    setTimeout(() => {
      console.log('[settings-recovery] Unlock dialog closed, opening settings')
      
      // Find the Settings menu item
      const settingsMenuItems = document.querySelectorAll('[role="menuitem"]')
      let settingsTrigger = null
      
      settingsMenuItems.forEach(item => {
        if (item.textContent.includes('Settings')) {
          settingsTrigger = item
        }
      })
      
      if (settingsTrigger) {
        console.log('[settings-recovery] Clicking settings trigger')
        settingsTrigger.click()
        
        // Wait for settings dialog to render
        this.waitForJournalProtectionTab()
      } else {
        console.error('[settings-recovery] Settings trigger not found')
      }
    }, 300)
  }

  waitForJournalProtectionTab() {
    let attempts = 0
    const maxAttempts = 30
    
    const checkForTab = () => {
      attempts++
      
      // Look for the journal protection tab using the correct selector
      const journalProtectionTab = document.querySelector('button[data-value="journal_protection"][data-ruby-ui--tabs-target="trigger"]')
      
      console.log('[settings-recovery] Attempt', attempts, '- Found tab:', journalProtectionTab)
      
      if (journalProtectionTab) {
        console.log('[settings-recovery] Found Journal Protection tab, clicking')
        journalProtectionTab.click()
        
        // Wait then load recovery form
        setTimeout(() => {
          console.log('[settings-recovery] Loading recovery form')
          fetch('/settings/journal_protection?tab_form=recover', {
            headers: {
              'Accept': 'text/vnd.turbo-stream.html'
            }
          })
            .then(response => response.text())
            .then(html => {
              Turbo.renderStreamMessage(html)
              console.log('[settings-recovery] Recovery form loaded')
            })
            .catch(error => {
              console.error('[settings-recovery] Error loading recovery form:', error)
            })
        }, 300)
      } else if (attempts < maxAttempts) {
        setTimeout(checkForTab, 100)
      } else {
        console.error('[settings-recovery] Tab never found after', maxAttempts, 'attempts')
      }
    }
    
    setTimeout(checkForTab, 300)
  }
}
