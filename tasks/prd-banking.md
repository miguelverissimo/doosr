# PRD: Banking - Expense Tracking & Analysis

## Introduction

Add a banking feature that allows users to track their expenses, analyze spending patterns, and identify recurring transactions. Users can manually create entries or import transactions via CSV files. The system provides categorization (both manual and automatic), pattern detection for recurring items, and visual analytics with totals and graphs.

## Goals

- Allow users to view all their banking transactions in one place
- Support manual transaction entry and bulk CSV import
- Prevent duplicate imports through row hashing
- Categorize transactions manually and automatically based on description patterns
- Detect and highlight recurring transactions
- Provide spending analytics: totals, category breakdowns, and graphs
- Enable efficient transaction management with sorting, filtering, and pagination

## User Stories

### US-001: Create BankTransaction model and database schema
**Description:** As a developer, I need to store bank transactions with all required fields so they persist and can be queried efficiently.

**Acceptance Criteria:**
- [ ] Create `BankTransaction` model with fields: `date` (date), `description` (string), `value` (decimal), `row_hash` (string, unique index), `category_id` (foreign key, nullable), `user_id` (foreign key)
- [ ] Add `row_hash` unique index scoped to user for deduplication
- [ ] Add indexes on `date`, `category_id`, and `user_id` for query performance
- [ ] Generate and run migration successfully
- [ ] Typecheck/lint passes

### US-002: Create Category model
**Description:** As a developer, I need to store categories that can be assigned to transactions.

**Acceptance Criteria:**
- [ ] Create `Category` model with fields: `name` (string), `color` (string for hex color), `user_id` (foreign key)
- [ ] Add unique index on `name` scoped to user
- [ ] Seed default categories: Groceries, Fuel, Subscriptions, Dining, Transport, Shopping, Bills, Entertainment, Health, Other
- [ ] Generate and run migration successfully
- [ ] Typecheck/lint passes

### US-003: Create CategoryPattern model for auto-categorization
**Description:** As a developer, I need to store patterns that automatically assign categories based on transaction descriptions.

**Acceptance Criteria:**
- [ ] Create `CategoryPattern` model with fields: `pattern` (string), `category_id` (foreign key), `user_id` (foreign key)
- [ ] Pattern field stores case-insensitive substring to match against descriptions
- [ ] Add unique index on `pattern` scoped to user
- [ ] Generate and run migration successfully
- [ ] Typecheck/lint passes

### US-004: Build CSV import service with background processing
**Description:** As a developer, I need a service that processes CSV files in the background and imports transactions without duplicates.

**Acceptance Criteria:**
- [ ] Create `Banking::ImportService` that accepts a CSV file and user
- [ ] Parse CSV with headers: Date, Description, Value
- [ ] Handle date format `DD-MM-YYYY`
- [ ] Handle value format with comma as decimal separator (e.g., `"9,109.70"` or `-24.28`)
- [ ] Generate `row_hash` as SHA256 of `"#{date}|#{description}|#{value}"` normalized
- [ ] Skip rows where `row_hash` already exists for user
- [ ] Create `Banking::ImportJob` that calls the service (Solid Queue)
- [ ] Return import results: total rows, imported count, skipped count (duplicates)
- [ ] Typecheck/lint passes

### US-005: Apply automatic categorization on import
**Description:** As a developer, I need transactions to be automatically categorized during import based on existing patterns.

**Acceptance Criteria:**
- [ ] During import, match each transaction description against user's CategoryPatterns
- [ ] If pattern matches (case-insensitive substring), assign that category
- [ ] First matching pattern wins (ordered by pattern length, longest first)
- [ ] Leave category as null if no pattern matches
- [ ] Typecheck/lint passes

### US-006: Build banking dashboard page
**Description:** As a user, I want a dedicated banking section where I can see my transactions and analytics.

**Acceptance Criteria:**
- [ ] Add `/banking` route accessible from main navigation
- [ ] Create `BankingController#index` action
- [ ] Page shows summary cards at top: Total Income, Total Expenses, Net Balance (for selected period)
- [ ] Default period is current month
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-007: Display transactions table with pagination
**Description:** As a user, I want to see my transactions in a paginated table so I can browse through large datasets.

**Acceptance Criteria:**
- [ ] Table columns: Date, Description, Category, Value
- [ ] Rows sorted by date descending (newest first) by default
- [ ] Negative values (expenses) shown in red, positive (income) in green
- [ ] Paginate with 50 items per page
- [ ] Show pagination controls (previous/next, page numbers)
- [ ] Use Turbo Frames for pagination without full page reload
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-008: Add sorting to transactions table
**Description:** As a user, I want to sort the transaction table by different columns to organize my data.

**Acceptance Criteria:**
- [ ] Clickable column headers for: Date, Description, Category, Value
- [ ] Toggle between ascending/descending on click
- [ ] Show sort indicator (arrow) on active sort column
- [ ] Sorting persists in URL params
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-009: Add filtering to transactions table
**Description:** As a user, I want to filter transactions by date range, category, and amount to find specific entries.

**Acceptance Criteria:**
- [ ] Filter panel above table with: Date From, Date To, Category (dropdown), Min Amount, Max Amount
- [ ] Filters apply via Turbo Frame update (no full page reload)
- [ ] Filter state persists in URL params
- [ ] "Clear filters" button resets all filters
- [ ] Show active filter count badge
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-010: Add search to transactions table
**Description:** As a user, I want to search transactions by description to quickly find specific entries.

**Acceptance Criteria:**
- [ ] Search input field in filter panel
- [ ] Case-insensitive partial match on description
- [ ] Debounce search input (300ms)
- [ ] Search term persists in URL params
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-011: Create manual transaction entry form
**Description:** As a user, I want to manually add individual transactions when I don't have a CSV.

**Acceptance Criteria:**
- [ ] "Add Transaction" button opens dialog (using RubyUI::Dialog)
- [ ] Form fields: Date (date picker), Description (text), Value (number with decimals), Category (dropdown)
- [ ] Value accepts negative (expense) or positive (income) numbers
- [ ] On submit, create transaction and update table via Turbo Stream
- [ ] Show success toast after creation
- [ ] Generate row_hash for manual entries too (for deduplication)
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-012: Create CSV upload interface
**Description:** As a user, I want to upload CSV files to bulk import my bank transactions.

**Acceptance Criteria:**
- [ ] "Import CSV" button opens dialog
- [ ] File input accepts `.csv` files only
- [ ] Show expected format hint: "Date,Description,Value"
- [ ] On submit, show loading indicator and close dialog
- [ ] Process import in background job
- [ ] Show toast notification when import completes (via Turbo Stream broadcast)
- [ ] Display import results: "Imported X transactions, Y duplicates skipped"
- [ ] Refresh transactions table after import
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-013: Edit transaction inline
**Description:** As a user, I want to edit a transaction to fix errors or update the category.

**Acceptance Criteria:**
- [ ] Click on transaction row or edit icon opens edit dialog
- [ ] Pre-populated form with current values
- [ ] Can edit: Date, Description, Value, Category
- [ ] On save, update table row via Turbo Stream
- [ ] Show success toast after update
- [ ] Recalculate row_hash if date/description/value changes
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-014: Delete transaction with confirmation
**Description:** As a user, I want to delete transactions I no longer need.

**Acceptance Criteria:**
- [ ] Delete button/icon on each transaction row
- [ ] Opens RubyUI::AlertDialog confirmation
- [ ] On confirm, delete and remove row via Turbo Stream
- [ ] Show success toast after deletion
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-015: Bulk select and delete transactions
**Description:** As a user, I want to select multiple transactions and delete them at once.

**Acceptance Criteria:**
- [ ] Checkbox on each transaction row
- [ ] "Select all" checkbox in header (selects visible page only)
- [ ] When items selected, show bulk action bar with "Delete Selected (N)"
- [ ] Bulk delete opens RubyUI::AlertDialog confirmation
- [ ] On confirm, delete all and update table via Turbo Stream
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-016: Manage categories
**Description:** As a user, I want to create, edit, and delete categories to organize my transactions.

**Acceptance Criteria:**
- [ ] "Manage Categories" link/button accessible from banking page
- [ ] Opens categories management dialog or page
- [ ] List all categories with name and color swatch
- [ ] Add new category: name and color picker
- [ ] Edit existing category: change name or color
- [ ] Delete category (with confirmation, sets transactions to null category)
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-017: Assign category to transaction
**Description:** As a user, I want to quickly assign or change a transaction's category without opening full edit.

**Acceptance Criteria:**
- [ ] Category cell in table is clickable
- [ ] Click opens dropdown with all categories + "None" option
- [ ] Selecting category updates immediately via Turbo Stream
- [ ] Show brief success indicator (checkmark or highlight)
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-018: Create auto-categorization pattern from transaction
**Description:** As a user, I want to create a pattern from a transaction so future similar transactions are auto-categorized.

**Acceptance Criteria:**
- [ ] "Create Pattern" option in transaction context menu or edit dialog
- [ ] Opens dialog pre-filled with description (user can modify to make pattern)
- [ ] Select category to assign
- [ ] On save, create CategoryPattern
- [ ] Option to "Apply to existing" - bulk update matching uncategorized transactions
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-019: Manage auto-categorization patterns
**Description:** As a user, I want to view and manage my categorization patterns.

**Acceptance Criteria:**
- [ ] "Manage Patterns" link accessible from banking page
- [ ] List all patterns with: pattern text, assigned category, match count
- [ ] Edit pattern text or category
- [ ] Delete pattern (with confirmation)
- [ ] Test pattern: show how many existing transactions would match
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-020: Detect recurring transactions
**Description:** As a user, I want the system to identify recurring transactions so I can see my regular expenses.

**Acceptance Criteria:**
- [ ] Create `Banking::RecurringDetectionService` that analyzes transactions
- [ ] Identify recurring patterns: similar description + similar amount + regular interval
- [ ] Tolerance: amount within 10%, description similarity > 80% (fuzzy match)
- [ ] Detect intervals: weekly, monthly, yearly
- [ ] Store detected recurring groups (new model or computed)
- [ ] Typecheck/lint passes

### US-021: Display recurring transactions section
**Description:** As a user, I want to see a summary of my recurring expenses.

**Acceptance Criteria:**
- [ ] "Recurring" tab or section on banking dashboard
- [ ] List detected recurring transactions grouped by pattern
- [ ] Show: description pattern, average amount, frequency, last occurrence
- [ ] Show total monthly recurring expense
- [ ] Click to see all transactions in that recurring group
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-022: Display category breakdown chart
**Description:** As a user, I want to see a pie/donut chart showing spending by category.

**Acceptance Criteria:**
- [ ] Category breakdown chart on banking dashboard
- [ ] Donut chart showing expense distribution by category
- [ ] Include legend with category names and percentages
- [ ] Click category slice to filter table to that category
- [ ] Handle "Uncategorized" as a slice
- [ ] Respect current date range filter
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-023: Display spending over time graph
**Description:** As a user, I want to see a line/bar chart of my spending over time to identify trends.

**Acceptance Criteria:**
- [ ] Time series chart on banking dashboard
- [ ] Show daily/weekly/monthly totals based on date range
- [ ] Separate lines/bars for income and expenses
- [ ] X-axis: time periods, Y-axis: amounts
- [ ] Hover to see exact values
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-024: Display monthly totals summary
**Description:** As a user, I want to see a quick summary of totals for the selected period.

**Acceptance Criteria:**
- [ ] Summary cards at top of banking dashboard
- [ ] Cards: Total Income (positive values sum), Total Expenses (negative values sum), Net (difference)
- [ ] Cards update when date range filter changes
- [ ] Use color coding: green for income, red for expenses, blue/gray for net
- [ ] Show comparison with previous period (e.g., "+12% from last month")
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-025: Date range quick filters
**Description:** As a user, I want quick buttons to filter by common date ranges.

**Acceptance Criteria:**
- [ ] Quick filter buttons: "This Month", "Last Month", "Last 3 Months", "This Year", "All Time"
- [ ] Clicking updates date range filter and refreshes data
- [ ] Active quick filter highlighted
- [ ] Custom date range still available via date pickers
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

## Functional Requirements

- FR-1: Store bank transactions with date, description, value, category, and unique row_hash per user
- FR-2: Generate row_hash as SHA256 of normalized `"#{date}|#{description}|#{value}"` string
- FR-3: Reject duplicate imports by checking row_hash uniqueness scoped to user
- FR-4: Process CSV imports in background jobs using Solid Queue
- FR-5: Parse CSV with format: Date (DD-MM-YYYY), Description (string), Value (decimal with comma or period)
- FR-6: Support both comma and period as decimal separators in value field
- FR-7: Handle quoted CSV fields containing commas (standard CSV parsing)
- FR-8: Allow manual transaction creation, editing, and deletion
- FR-9: Support bulk selection and deletion of transactions
- FR-10: Store categories with name and color per user
- FR-11: Allow creating, editing, and deleting categories
- FR-12: Store categorization patterns that map description substrings to categories
- FR-13: Auto-apply matching patterns during CSV import
- FR-14: Allow quick category assignment from table without full edit dialog
- FR-15: Detect recurring transactions based on description similarity, amount tolerance, and time intervals
- FR-16: Calculate and display totals: income, expenses, net balance
- FR-17: Calculate totals by category for breakdown chart
- FR-18: Generate time series data for spending over time chart
- FR-19: Support filtering by: date range, category, amount range, search term
- FR-20: Support sorting by: date, description, category name, value
- FR-21: Paginate transaction list with 50 items per page
- FR-22: Broadcast import completion via Turbo Stream to update UI

## Non-Goals

- No support for multiple bank accounts (single account only)
- No bank API integrations or automatic transaction fetching
- No budget setting or budget vs actual tracking
- No bill reminders or payment scheduling
- No multi-currency support (single currency assumed)
- No transaction attachments (receipts, images)
- No sharing or export of banking data

## Design Considerations

- Follow existing Doosr UI patterns and component library
- Use RubyUI components: Dialog, AlertDialog, Button, Input, Form, Badge, Table
- Use Phlex for all views (no ERB)
- Charts: Use Chartkick gem with Chart.js for pie/donut and line/bar charts
- Color scheme for categories should be user-customizable
- Transaction table should feel fast even with thousands of rows
- Mobile-specific views - THIS IS A MOBILE-FIRST APP!!!! 

## Technical Considerations

- Use Solid Queue for background CSV processing
- Use Turbo Streams for real-time UI updates after import completes
- Index frequently queried columns: date, category_id, user_id, row_hash
- Consider database-level constraints for row_hash uniqueness
- Run recurring detection automatically after each import completes (in same background job)
- Use Chartkick gem for charts (add `gem 'chartkick'` and `pin 'chartkick', 'Chart.bundle'`)
- CSV parsing should handle malformed rows gracefully (skip and report)
- Validate CSV file size (max 1 MB) before queuing import job

## Success Metrics

- CSV import processes 1000+ transactions in under 30 seconds
- Duplicate detection is 100% accurate (no false positives/negatives)
- Transaction table loads in under 500ms with 10,000+ transactions
- Users can categorize a transaction in 2 clicks or less
- Auto-categorization correctly assigns 70%+ of recurring transactions

## Decisions

1. **File format support:** CSV only. This is the simplest approach and covers most bank exports. OFX/QIF can be added later if needed.

2. **Charting library:** Chartkick Ruby gem. Provides a simple Ruby API and uses Chart.js under the hood. Easy integration with Rails views.

3. **Recurring detection timing:** Automatically after each import. The system will analyze transactions and update recurring patterns after every CSV import completes.

4. **Pattern learning:** Auto-suggest pattern creation after manual category assignment. When a user assigns a category to an uncategorized transaction, prompt them to create a pattern for similar future transactions.

5. **Maximum CSV file size:** 1 MB (~10,000 transactions). This is sufficient for typical personal banking exports and keeps upload/processing times reasonable.
