# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Doosr is a daily task management application built with Rails 8.1, Hotwire (Turbo + Stimulus), Phlex for components, and Ruby UI. Users manage their tasks through Days (daily views), Lists (reusable item collections), and Items (individual tasks/sections).

## Technology Stack

- **Backend**: Rails 8.1 with PostgreSQL
- **Frontend**: Hotwire (Turbo + Stimulus), importmap for JS
- **Styling**: Tailwind CSS
- **Components**: Phlex (Ruby-based view components), Ruby UI component library
- **Authentication**: Devise with OmniAuth (Google, GitHub)
- **Job Queue**: Solid Queue
- **Cache**: Solid Cache
- **WebSockets**: Action Cable (Solid Cable)

## Development Commands

### Server Management
- **CRITICAL**: Never start, stop, or restart the server unless explicitly requested by the user
- If server restart is needed, ask the user to do it
- Server runs via: `bin/rails server` (but don't run this)

### Testing
```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/models/item_test.rb

# Run specific test
bin/rails test test/models/item_test.rb:10
```

### Database
```bash
# Run pending migrations
bin/rails db:migrate

# Check migration status
bin/rails db:migrate:status

# Rollback last migration
bin/rails db:rollback

# Reset database (development only)
bin/rails db:reset
```

### Asset Pipeline
```bash
# Build Tailwind CSS
bin/rails tailwindcss:build

# Watch Tailwind CSS for changes (runs in background)
bin/rails tailwindcss:watch

# Add JavaScript packages via importmap
bin/importmap pin <package-name>
```

### Code Quality
```bash
# Run RuboCop linter
bin/rubocop

# Run Brakeman security scanner
bin/brakeman

# Run Bundler audit for security vulnerabilities
bin/bundler-audit
```

### Generators
```bash
# Generate model
bin/rails generate model ModelName field:type

# Generate controller
bin/rails generate controller ControllerName action1 action2

# Generate Phlex component
bin/rails generate phlex:component ComponentName

# View routes
bin/rails routes
```

## Core Architecture

### Data Model Hierarchy

The app uses a polymorphic tree structure via the `Descendant` model:

```
User
├── Day (one per date)
│   └── Descendant (contains active_items and inactive_items arrays)
│       └── Item IDs in display order
└── List (reusable collections)
    └── Descendant (contains active_items and inactive_items arrays)
        └── Item IDs in display order
```

**Descendant Model**: Central to the architecture. Stores ordered arrays of item IDs:
- `active_items`: Array of item IDs in display order (visible, active tasks)
- `inactive_items`: Array of item IDs in display order (completed/dropped/deferred)
- Used by both Day and List models polymorphically
- Items can be nested infinitely: any Item can have its own Descendant with child items

### Key Models

**Item** (`app/models/item.rb`):
- Core building block of the app
- Types: `completable` (todos), `section` (headers), `reusable` (templates), `trackable` (habits)
- States: `todo`, `done`, `dropped`, `deferred`
- Can have nested items via its own Descendant record
- State transitions (`set_done!`, `set_todo!`, etc.) automatically manage Descendant arrays

**Day** (`app/models/day.rb`):
- Represents a user's daily view (one per date per user)
- States: `open` (active), `closed` (archived)
- Has one Descendant containing the day's item IDs
- Tracks import chains (days can be imported from previous days)

**List** (`app/models/list.rb`):
- Reusable item collections (e.g., shopping lists, checklists)
- Types: `private_list`, `public_list`, `shared_list`
- Has one Descendant containing list item IDs
- Public lists accessible via slug: `/p/lists/:slug`

**Descendant** (`app/models/descendant.rb`):
- Stores ordered arrays of item IDs for polymorphic parents
- Methods: `add_active_item`, `remove_active_item`, `add_inactive_item`, etc.
- Query: `Descendant.containing_item(item_id)` finds which parent contains an item

### Controllers

**Items vs Reusable Items**:
- `ItemsController`: Handles items within Days
- `ReusableItemsController`: Handles items within Lists
- Both support: create, update, destroy, toggle_state, move, reparent, actions_sheet, edit_form

### Service Objects

Located in `app/services/`:
- `Days::ImportService`: Import items from a previous day
- `Days::OpenDayService`: Open or create today's day
- `Items::DeferService`: Defer items to future dates
- `Items::ReparentService`: Move items between parents (new)
- `ItemTree::Build`: Build tree structure for nested items (new)

### Frontend Architecture

**Stimulus Controllers** (`app/javascript/controllers/`):
- `item_controller.js`: Item interactions (delete, defer, state toggle)
- `item_form_controller.js`: Item creation/edit forms
- `day_move_controller.js`: Move items up/down in day view
- `item_move_controller.js`: Move items up/down in list view
- `defer_calendar_controller.js`: Calendar for deferring items
- `item_autocomplete_controller.js`: Autocomplete for item titles

**Phlex Components** (`app/views/`):
- All views are Phlex components (Ruby-based, not ERB)
- Layouts: `app/views/layouts/app_layout.rb`, `auth_layout.rb`
- Components: `app/views/items/`, `app/views/days/`, `app/views/lists/`

## Critical Development Rules

### Phlex Components
- ❌ **ABSOLUTELY NEVER EVER USE `onclick`, `onchange`, or ANY `on*` EVENT ATTRIBUTES IN PHLEX** ❌
  - They throw `Phlex::ArgumentError` and will break the application
  - This includes: `onclick`, `onchange`, `onsubmit`, `onload`, `oninput`, `onfocus`, `onblur`, etc.
  - **NO EXCEPTIONS** - even simple things like `onclick="event.stopPropagation()"` are forbidden
- ✅ **ALWAYS use Stimulus controllers with data attributes instead**:
  - `data: { action: "click->controller#method" }`
  - Example: Instead of `onclick="alert('hi')"`, create a Stimulus controller method
- Use Ruby UI components from the ruby_ui gem - do not create raw HTML/JS

### UI Feedback
- **Every backend request MUST show a loading indicator**
- For form submissions: Use `window.toast(message, { type: "loading", description: "Please wait" })`
  - Dismiss on `turbo:submit-end` or response received
  - Applies to: create, update, delete, move, toggle, defer, reparent
- **For pagination and filters**: Use loading spinner pattern (see below)

#### Pagination with Loading Spinner Pattern
**CRITICAL: All paginated list views MUST show a loading spinner during data fetching.**

Example implementation (see `app/views/accounting/invoices/_list.rb` and `app/views/accounting/invoices/_list_content.rb`):

1. **Stimulus Controller** (`app/javascript/controllers/invoice_filter_controller.js`):
   ```javascript
   import { Controller } from "@hotwired/stimulus"

   export default class extends Controller {
     static targets = ["spinner", "content"]

     connect() {
       this.element.addEventListener("turbo:before-stream-render", () => this.hideSpinner())
     }

     showSpinner() {
       if (this.hasSpinnerTarget && this.hasContentTarget) {
         this.spinnerTarget.classList.remove("hidden")
         this.contentTarget.classList.add("hidden")
       }
     }

     hideSpinner() {
       if (this.hasSpinnerTarget && this.hasContentTarget) {
         this.spinnerTarget.classList.add("hidden")
         this.contentTarget.classList.remove("hidden")
       }
     }
   }
   ```

2. **Container View** (with controller, spinner, and content targets):
   ```ruby
   div(class: "flex flex-col gap-4", id: "container", data: { controller: "invoice-filter" }) do
     # Filter/pagination controls with click action
     div(class: "flex gap-2") do
       render ::Components::BadgeLink.new(
         href: view_context.invoices_path(filter: "unpaid"),
         data: {
           turbo_stream: true,
           action: "click->invoice-filter#showSpinner"
         }
       ) { "Unpaid" }
     end

     # Loading spinner (hidden by default)
     div(
       id: "loading_spinner",
       class: "hidden",
       data: { invoice_filter_target: "spinner" }
     ) do
       render ::Components::Shared::LoadingSpinner.new(message: "Loading...")
     end

     # Content area
     div(data: { invoice_filter_target: "content" }) do
       render ::Views::ListContent.new(user: @user, filter: @filter, page: @page)
     end
   end
   ```

3. **Pagination Links** (in list content view):
   ```ruby
   PaginationItem(
     href: view_context.invoices_path(filter: @filter, page: page_num),
     active: page_num == current_page,
     data: {
       turbo_stream: true,
       action: "click->invoice-filter#showSpinner"  # CRITICAL: Must trigger spinner
     }
   ) { page_num.to_s }
   ```

4. **Margin for Pagination**:
   ```ruby
   # Always wrap pagination in a div with top margin
   if @items.total_pages > 1
     div(class: "mt-6") do
       render_pagination
     end
   end
   ```

**Key Points:**
- Loading spinner MUST be shown for all filter changes and pagination navigation
- Spinner automatically hides when turbo stream response is received
- All clickable filter/pagination elements must have `action: "click->controller#showSpinner"`
- Content area must have the `content` target
- Spinner must have the `spinner` target

### Drawer Navigation (CRITICAL - READ CAREFULLY)
**THIS IS EXTREMELY IMPORTANT. VIOLATING THESE RULES CREATES MULTIPLE OVERLAYS AND WASTES USER MONEY.**

#### Drawer Architecture
The drawer system has two layers:
1. **ActionsSheet**: The full drawer (backdrop + sheet container + close button) with `id="item_actions_sheet"`
2. **Sheet Content**: The replaceable content area with `id="sheet_content_area"` inside the drawer

#### Opening vs Navigating
- **Opening a new drawer** (from day/list view → actions sheet):
  - Use `turbo_stream.append("body", ActionsSheet.new(...))`
  - This creates the ENTIRE drawer structure including backdrop

- **Navigating within a drawer** (actions → defer/recurrence/edit):
  - Use `turbo_stream.replace("sheet_content_area", OptionsView.new(...))`
  - This ONLY replaces the content, keeping the same backdrop and close button

#### Controller Pattern for Option Screens
**ALWAYS use this exact pattern for defer_options, recurrence_options, edit_form, etc.**:
```ruby
def defer_options  # or recurrence_options, edit_form, etc.
  @item = @acting_user.items.find(params[:id])
  @day = @acting_user.days.find(params[:day_id]) if params[:day_id].present?

  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: turbo_stream.replace(
        "sheet_content_area",
        ::Views::Items::DeferOptions.new(item: @item, day: @day)
      )
    end
  end
end
```

#### View Pattern for Option Screens
**ALWAYS wrap your option view content in a div with id="sheet_content_area"**:
```ruby
def view_template
  div(id: "sheet_content_area", data: { controller: "your-controller" }) do
    SheetHeader do
      SheetTitle { "Your Title" }
    end
    SheetMiddle do
      # Your content
    end
    # Cancel button with from_edit_form: true
  end
end
```

#### Common Mistakes That Create Multiple Overlays
- ❌ **NEVER** create backdrop divs in option views (defer, recurrence, edit)
- ❌ **NEVER** use `turbo_stream.append` for navigating within a drawer
- ❌ **NEVER** forget to wrap option content with `id="sheet_content_area"`
- ❌ **NEVER** create new drawer structures in option views

### Drawer Cancel Buttons
- **CRITICAL**: All Cancel buttons in drawer option screens MUST return to the item actions drawer
- **MUST include `from_edit_form: true` parameter**:
  ```ruby
  a(
    href: actions_sheet_item_path(@item, day_id: @day&.id, from_edit_form: true),
    data: { turbo_stream: true },
    class: "flex-1 h-12 px-4 py-2 border border-input bg-background hover:bg-accent hover:text-accent-foreground rounded-md font-medium transition-colors flex items-center justify-center"
  ) { "Cancel" }
  ```

### Item State Transitions (CRITICAL - READ CAREFULLY)
**THIS IS ABSOLUTELY CRITICAL. VIOLATING THESE RULES BREAKS RECURRENCE, DESCENDANT MANAGEMENT, AND OTHER CORE FEATURES.**

#### Single Code Path Rule
**NEVER create multiple code paths for the same user action.** Every state change MUST go through the same code path regardless of where the user triggers it (checkbox, button, keyboard, etc.).

#### State Transition Methods
ALL item state changes MUST go through these methods in `Item` model:
- `set_done!` - Mark item as done (handles Descendant arrays, recurrence scheduling)
- `set_todo!` - Mark item as todo (handles Descendant arrays, deletes next recurrence)
- `set_dropped!` - Mark item as dropped (handles Descendant arrays)
- `set_deferred!(date)` - Defer item to future date (handles Descendant arrays)

**NEVER use `@item.update(state: ...)` or `@item.update!(state: ...)` to change state** - this bypasses critical logic:
- ❌ Descendant array management (moving between active_items/inactive_items)
- ❌ Recurrence scheduling (creating next occurrence when completing recurring items)
- ❌ Recurring item cleanup (deleting next occurrence when uncompleting)
- ❌ Timestamp tracking (done_at, dropped_at, deferred_at)

#### Controller Actions
Use the `toggle_state` action for ALL state changes from the UI:
- **For day items**: `toggle_state_item_path(@item)` → `ItemsController#toggle_state`
- **For list items**: `toggle_state_reusable_item_path(@item)` → `ReusableItemsController#toggle_state`

**NEVER route checkboxes, buttons, or other UI elements to the `update` action for state changes.**

#### Example: Checkbox Implementation
```ruby
def render_checkbox
  # ALWAYS use toggle_state endpoint for both days and lists
  # This ensures state changes go through set_done!/set_todo! methods
  toggle_path = if @list
    toggle_state_reusable_item_path(@item)
  else
    toggle_state_item_path(@item)
  end

  form(action: toggle_path, method: "post", ...) do
    csrf_token_field
    input(type: "hidden", name: "_method", value: "patch")
    # Always use state param (not item[state])
    input(type: "hidden", name: "state", value: @item.done? ? "todo" : "done")
    # checkbox input
  end
end
```

#### Why This Matters
If a checkbox uses `item_path(@item)` (update action) while a button uses `toggle_state_item_path(@item)`:
- ✓ Button → `toggle_state` → `set_done!` → Recurrence works, Descendant arrays updated
- ✗ Checkbox → `update` → `@item.update(state: :done)` → Recurrence BROKEN, Descendant arrays NOT updated

This creates an inconsistent user experience where the same action works differently depending on how it's triggered.

### Item Movement Rules
Active items can move within their array IF:
1. The day/list is not closed
2. The item is in the `active_items` array
3. The item is not at array boundary (position 0 for up, last position for down)

Do NOT check item state (deferred, dropped, done) - only check day state and array position.

### Button Variants
Follow Ruby UI button conventions:
- Primary action: `Button(variant: :primary)`
- Secondary action: `Button(variant: :secondary)`
- Destructive action: `Button(variant: :destructive)`
- Options: `Button(variant: :outline)`
- Add `icon: true` for icon-only buttons
- Add `type: :submit` for form submission buttons

## Routes Structure

Key route patterns:
- Days: `GET /day`, `POST /days`, `PATCH /days/:id/close`, `POST /days/import`
- Lists: `resources :lists` with `GET /p/lists/:slug` for public access
- Items: `resources :items` (day items) and `resources :reusable_items` (list items)
- Both item controllers have: `actions`, `edit_form`, `toggle_state`, `move`, `reparent`, `debug`
- Settings: `resource :settings` with nested section management

## Authentication

- Devise with email/password
- OmniAuth providers: Google, GitHub
- Controllers in `app/controllers/users/`
- Authenticated users see day view, unauthenticated see sign-in

## Testing

- Minitest framework
- Test files mirror app structure: `test/models/`, `test/controllers/`, `test/services/`
- Fixtures in `test/fixtures/`
- System tests use Capybara + Selenium WebDriver

## Key Patterns

1. **State transitions manage arrays**: When an item state changes (todo → done), the state transition method automatically moves the item between `active_items` and `inactive_items` arrays in the containing Descendant.

2. **Infinite nesting**: Items can have their own Descendant with nested items. Use `ItemTree::Build` service to construct tree views.

3. **Import chains**: Days can be imported from previous days, creating chains tracked via `imported_from_day` and `imported_to_day`.

4. **Public lists**: Lists with `list_type: :public_list` are accessible via slug without authentication.

5. **ULID for slugs**: Public lists use ULID for URL-safe unique identifiers.

6. **Class organization**: Never use the `public` keyword and use a single `private` keyword per class. Keep all public methods before the `private` keyword.

7. **Class references with :: prefix**: ALWAYS prefix class references with `::` to reference top-level constants and avoid namespace collisions. This is especially critical when referencing classes from within module namespaces.
   - ✅ CORRECT: `::FixedCalendar::Converter.ritual_for_day`
   - ❌ WRONG: `FixedCalendar::Converter.ritual_for_day` (inside `Views::FixedCalendar` module)
   - The `::` prefix ensures Ruby looks for the class at the top level, not within the current module
   - Example error without `::`: `NameError (uninitialized constant Views::FixedCalendar::Converter)` when trying to reference `FixedCalendar::Converter` from within `Views::FixedCalendar` module
