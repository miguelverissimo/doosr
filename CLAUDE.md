# CLAUDE.md

Doosr is a Rails 8.1 daily task management app using Hotwire (Turbo + Stimulus), Phlex components, and Ruby UI.

## Tech Stack
- **Backend**: Rails 8.1, PostgreSQL, Devise + OmniAuth (Google, GitHub)
- **Frontend**: Hotwire, Phlex (no ERB), Tailwind CSS, Ruby UI components, importmap
- **Infrastructure**: Solid Queue/Cache/Cable, Web Push API (VAPID), Coolify deployment
- **Testing**: Minitest, Capybara + Selenium

## Deployment (Coolify)
Self-hosted Docker deployment. Environment variables and storage via Coolify UI. Migrations run automatically via `bin/docker-entrypoint`. Thruster web server on port 80. Access production console via Coolify Terminal.

## Core Architecture

### Data Model
Polymorphic tree structure via `Descendant` model:
- **User** → **Day** (one per date) → **Descendant** → Item IDs (ordered arrays)
- **User** → **List** (reusable collections) → **Descendant** → Item IDs
- **Descendant** stores `active_items` and `inactive_items` arrays (ordered item IDs)
- **Items** can nest infinitely (each Item can have its own Descendant with children)

### Key Models
- **Item**: Core building block. Types: `completable`, `section`, `reusable`, `trackable`. States: `todo`, `done`, `dropped`, `deferred`. State transitions (`set_done!`, `set_todo!`, etc.) automatically manage Descendant arrays and recurrence.
- **Day**: One per user per date. States: `open`, `closed`. Has one Descendant.
- **List**: Types: `private_list`, `public_list`, `shared_list`. Public lists accessible via slug.
- **Descendant**: Polymorphic parent for Day/List/Item. Methods: `add_active_item`, `remove_active_item`, etc.

### Controllers
- **ItemsController**: Day items
- **ReusableItemsController**: List items
- Both support: create, update, destroy, toggle_state, move, reparent, actions_sheet, edit_form

### Services
- `Days::ImportService`, `Days::OpenDayService`
- `Items::DeferService`, `Items::ReparentService`
- `ItemTree::Build` for nested item trees

## Critical Rules

### Following Instructions (ABSOLUTELY CRITICAL)
**❌ THERE IS ABSOLUTELY NO AUTONOMY TO CHANGE, INTERPRET, OR MODIFY USER INSTRUCTIONS ❌**

Follow user instructions EXACTLY as stated.

**NEVER:**
- Make "improvements" or "optimizations" that weren't requested
- Change the approach because you think there's a "better way"
- Add extra features or functionality not explicitly requested
- Modify scope or implementation details beyond what was instructed

**If you find yourself thinking "but it would be better if..." - STOP. Do what was instructed.**

### Phlex Components
**❌ ABSOLUTELY NEVER USE `on*` EVENT ATTRIBUTES IN PHLEX ❌**

They throw `Phlex::ArgumentError` and break the application.

**NEVER:**
- Use `onclick`, `onchange`, `onsubmit`, `onload`, `oninput`, `onfocus`, `onblur`, or ANY `on*` attributes
- Even simple things like `onclick="event.stopPropagation()"` are FORBIDDEN

**ALWAYS:**
- Use Stimulus controllers with `data: { action: "click->controller#method" }`

### SVG Icons (CRITICAL)
**❌ IT IS FORBIDDEN TO HAVE SVG ICONS IN `svg` ELEMENTS ❌**

**NEVER:**
- Create inline SVG elements in any view file
- Use `<svg>` tags directly

**ALWAYS:**
- Use icon classes from `app/components/icon/`
- Pattern: `render ::Components::Icon::Edit.new(size: "16")`
- New icons: Create class in `app/components/icon/` inheriting from `::Components::Icon::Base`

### State Transitions (ABSOLUTELY CRITICAL)
**❌ NEVER USE `@item.update(state: ...)` TO CHANGE STATE ❌**

This bypasses Descendant management, recurrence scheduling, and timestamp tracking.

**ALWAYS:**
- Use state transition methods: `set_done!`, `set_todo!`, `set_dropped!`, `set_deferred!(date)`
- Route ALL UI state changes to `toggle_state` action, NOT `update` action
- Single code path rule: same user action must go through same code regardless of trigger

**Why this matters:** If checkbox uses `update` while button uses `toggle_state`, recurrence and Descendant arrays break.

### Edit Actions (CRITICAL)
**❌ NEVER REPLACE ITEM INLINE WITH EDIT FORM ❌**

**WHEN A USER CLICKS EDIT, THEY MUST GET A DIALOG. NO EXCEPTIONS.**

**NEVER:**
- Use `turbo_stream.replace("item_#{@item.id}", EditForm)` - this is inline replacement
- Create separate EditForm component - use FormDialog for both create and edit
- Use `href` with `turbo_stream: true` on edit buttons

**ALWAYS:**
- Edit action: `turbo_stream.append("body", FormDialog)` - appends dialog
- Update action: `turbo_stream.remove("dialog_id")` - removes dialog
- Single FormDialog component for both create and edit
- Edit button uses Stimulus controller with `openDialog` method

### Delete Confirmations (ABSOLUTELY CRITICAL)
**❌ IT IS ABSOLUTELY FORBIDDEN TO USE `turbo_confirm` OR BROWSER CONFIRMATIONS ❌**

**NEVER:**
- Use `turbo_confirm` or `data-turbo-confirm` attributes
- Use browser's native confirm() function

**ALWAYS:**
- Use `RubyUI::AlertDialog` component
- Form inside AlertDialogFooter with `data: { action: "submit@document->ruby-ui--alert-dialog#dismiss" }`

### Drawer Navigation (CRITICAL)
**THIS IS EXTREMELY IMPORTANT. VIOLATING CREATES MULTIPLE OVERLAYS.**

**Opening drawer** (from day/list → actions):
- `turbo_stream.append("body", ActionsSheet)` - creates full drawer with backdrop

**Navigating within drawer** (actions → defer/recurrence/edit):
- `turbo_stream.replace("sheet_content_area", OptionsView)` - ONLY replaces content

**NEVER:**
- Create backdrop divs in option views (defer, recurrence, edit)
- Use `turbo_stream.append` for navigating within a drawer
- Forget to wrap option content with `id="sheet_content_area"`
- Create new drawer structures in option views

### Component Usage (CRITICAL)

#### Forms
**NEVER:**
- ❌ Use plain `form()` - ALWAYS use `RubyUI::Form.new`
- ❌ Use plain `label()` - ALWAYS use `RubyUI::FormFieldLabel.new`
- ❌ Use plain `input()` - ALWAYS use `RubyUI::Input.new` (even for hidden fields and CSRF tokens)
- ❌ Use plain `textarea()` - ALWAYS use `RubyUI::Textarea.new`
- ❌ Skip `RubyUI::FormField.new` wrapper for fields
- ❌ Skip `RubyUI::FormFieldError.new` for error display

**ALWAYS:**
- Wrap each field in `RubyUI::FormField.new`
- Use `RubyUI::Input.new(type: :hidden, ...)` even for CSRF tokens

#### Links and Buttons
**NEVER:**
- ❌ Use plain `a()` - ALWAYS use `::Components::ColoredLink.new`
- ❌ Use raw `<button>` or `<a>` tags with custom classes

**ALWAYS:**
- Buttons: `Button(variant: :primary)` - variants: primary, secondary, destructive, outline, ghost
- Links as buttons: `::Components::ColoredLink.new(href: path, variant: :primary)`
- Badges: `Badge(variant: :primary)`, `::Components::BadgeWithIcon.new(icon: :calendar)`, `::Components::BadgeLink.new(href: path)`

#### Date Inputs
**ALWAYS:**
- Include `class: "date-input-icon-light-dark"` on all `RubyUI::Input` with `type: :date`
- This ensures calendar icon is visible in dark mode

#### Dialogs via Buttons
**NEVER:**
- ❌ Use `ColoredLink` with `data: { turbo_stream: true }` to open dialogs - doesn't work
- ❌ Use `Button` with `href:` parameter for dialogs - doesn't work
- ❌ Use `Turbo.renderStreamMessage(html)` - doesn't work
- ❌ Cancel button with `click->ruby-ui--dialog#close` - doesn't work

**ALWAYS:**
- Create Stimulus controller with `openDialog()` method
- `openDialog()` fetches turbo_stream, uses DOMParser to extract template, appends to body
- Button has `data: { controller: "name", action: "click->name#openDialog" }`
- Dialog has unique ID
- Cancel button uses `click->modal-form#cancelDialog`

### UI Feedback
**CRITICAL: Every backend request MUST show loading indicator AND result (success/error)**

**NEVER:**
- ❌ Skip loading indicators
- ❌ Forget to dismiss modals/dialogs after save
- ❌ Skip success/error feedback
- ❌ Leave stale UI elements after operations
- ❌ Use full page redirects when turbo_stream updates would work

**ALWAYS:**
- Forms use `modal-form` controller with loading/success message values
- Paginated lists use loading spinner pattern (Stimulus controller with spinner/content targets, `showSpinner()` on click, auto-hide on turbo stream)
- CRUD operations: loading toast → close modal → update view → success toast (all in single turbo_stream array)

### Item Movement
Active items can move if: day/list not closed, item in active_items, not at boundary. Don't check item state.

## Key Patterns
1. State transitions automatically manage Descendant arrays
2. Items nest infinitely via their own Descendant
3. Days track import chains via `imported_from_day`/`imported_to_day`
4. Public lists use ULID slugs
5. Class references ALWAYS use `::` prefix to avoid namespace collisions
6. Single `private` keyword per class, all public methods before it

## Commands
**Never start/stop server** unless explicitly requested.

**Tests**: `bin/rails test [file[:line]]`
**DB**: `bin/rails db:migrate`, `bin/rails db:migrate:status`, `bin/rails db:rollback`
**Assets**: `bin/rails tailwindcss:build`, `bin/importmap pin <package>`
**Linting**: `bin/rubocop`, `bin/brakeman`, `bin/bundler-audit`
**Routes**: `bin/rails routes`
