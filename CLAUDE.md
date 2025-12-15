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
- **NEVER use `onclick`, `onchange`, or any `on*` event attributes** - they throw `Phlex::ArgumentError`
- Always use Stimulus controllers with data attributes: `data: { action: "click->controller#method" }`
- Use Ruby UI components from the ruby_ui gem - do not create raw HTML/JS

### UI Feedback
- **Every backend request MUST show a loading toast**
- Use: `window.toast(message, { type: "loading", description: "Please wait" })`
- Dismiss on `turbo:submit-end` or response received
- Applies to all actions: create, update, delete, move, toggle, defer, reparent

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
