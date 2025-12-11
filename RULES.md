# Development Rules for Claude Code

## Server Control

**CRITICAL: I DO NOT CONTROL THE SERVER. EVER.**

- The user controls the Rails server
- I must NEVER attempt to start, stop, or restart the server
- If I need the server restarted, I must ASK the user to do it
- I must NEVER use commands like `bin/rails server` or similar without explicit user request

## Phlex Components

**CRITICAL: NEVER USE onclick, onchange, or other on* attributes in Phlex components**

- Phlex does NOT support `onclick`, `onchange`, `onsubmit`, or any other `on*` event attributes
- These will throw `Phlex::ArgumentError: Unsafe attribute name detected`
- ALWAYS use Stimulus controllers instead with `data: { action: "event->controller#method" }`
- Example: Instead of `onclick: "doSomething()"`, use `data: { action: "click->my-controller#doSomething" }`
- Example: Instead of `onchange: "this.form.requestSubmit()"`, use `data: { action: "change->form#submit" }` or create a Stimulus controller

## Loading Feedback

**CRITICAL: EVERY UI action that makes a backend request MUST show a loading toast**

- Any form submission or action that goes to the backend MUST render a loading toast
- This applies to ALL actions: move, create, update, delete, toggle state, defer, reparent, etc.
- Use `window.toast(message, { type: "loading", description: "Please wait" })` before submission
- Dismiss the toast on turbo:submit-end or when response is received
- The loading toast provides visual feedback that the action is processing
- Without loading feedback, users don't know if their action was received

## Item Movement Rules

**Active items can ALWAYS move within their array (at ANY nesting level) IF:**

1. **The day is OPEN** (not closed)
2. **The item is in the active_items array** (meaning only active items can move, not inactive/done/dropped/deferred)
3. **The item is not at the boundary** (not at position 0 for up, not at last position for down)

**NO OTHER CONDITIONS MATTER** - Do not check:
- Whether the item is deferred
- Whether the item is dropped
- Whether the item is done
- Any other item state

The ONLY checks for move button disable logic are:
- Is the day closed? (`@day&.closed?`)
- Is the item at array boundary? (position 0 for up, last position for down)

## UI Layout Rules

**Follow mockups and designs EXACTLY as shown**

- If the user provides a mockup or image showing layout, implement it EXACTLY as shown
- Do not reorder elements unless explicitly asked
- Do not change visual hierarchy without confirmation
