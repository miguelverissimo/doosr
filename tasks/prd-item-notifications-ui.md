# PRD: Item Notifications UI

## Introduction

Implement the user interface for item notifications, allowing users to set time-based reminders on items, view and manage in-app notifications, and configure notification preferences. This PRD builds on the completed backend infrastructure (see `prd-item-notifications.md`).

## Goals

- Allow users to add, view, and remove reminders on items via the actions sheet
- Display notification bell in header with unread count badge
- Show notifications in a dropdown panel with click-to-navigate functionality
- Display reminder indicators on items (icon badge + time on hover/expand)
- Provide notification preferences tab in settings modal
- Navigate to day and highlight specific item when clicking a notification

## User Stories

### US-001: Add notification bell icon to header
**Description:** As a user, I want to see a notification bell in the header so I know where to find my notifications.

**Acceptance Criteria:**
- [ ] Bell icon added to header (use existing Icon component pattern)
- [ ] Bell icon positioned appropriately in header layout
- [ ] Bell is clickable and has hover state
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-002: Display unread notification count badge
**Description:** As a user, I want to see how many unread notifications I have so I know if something needs my attention.

**Acceptance Criteria:**
- [ ] Unread count badge displayed on bell icon when count > 0
- [ ] Badge hidden when count is 0
- [ ] Badge shows number (e.g., "3") for counts 1-99
- [ ] Badge shows "99+" for counts over 99
- [ ] Badge uses appropriate styling (small, red/accent colored circle)
- [ ] Count fetched from `current_user.unread_notifications_count`
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-003: Create notifications dropdown panel
**Description:** As a user, I want to click the bell to see my notifications in a dropdown so I can quickly review them.

**Acceptance Criteria:**
- [ ] Clicking bell opens dropdown panel below the icon
- [ ] Dropdown has header "Notifications" with "Mark all read" link
- [ ] Dropdown shows list of notifications (max 10, most recent first)
- [ ] Each notification shows: item title, reminder time, relative time (e.g., "2 hours ago")
- [ ] Empty state shows "No notifications" message
- [ ] Clicking outside dropdown closes it
- [ ] Uses Stimulus controller for open/close behavior
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-004: Create notification item component
**Description:** As a user, I want each notification in the dropdown to be clickable so I can navigate to the related item.

**Acceptance Criteria:**
- [ ] Create `Components::NotificationItem` Phlex component
- [ ] Unread notifications have visual distinction (bolder text or background)
- [ ] Read notifications appear muted/lighter
- [ ] Hover state indicates clickability
- [ ] Component receives notification record and renders appropriately
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-005: Implement mark all read functionality
**Description:** As a user, I want to mark all notifications as read so I can clear my notification count.

**Acceptance Criteria:**
- [ ] "Mark all read" link in dropdown header
- [ ] Clicking triggers POST to notifications controller
- [ ] Controller calls `Notifications::MarkAllReadService`
- [ ] Badge count updates to 0 via Turbo Stream
- [ ] Notifications in dropdown update to read state via Turbo Stream
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-006: Implement click-to-navigate for notifications
**Description:** As a user, I want to click a notification to go to that item so I can see what I was reminded about.

**Acceptance Criteria:**
- [ ] Clicking notification navigates to the day containing the item
- [ ] After navigation, the specific item is scrolled into view
- [ ] The item is briefly highlighted (flash animation or background color)
- [ ] Notification is marked as read when clicked
- [ ] Dropdown closes after click
- [ ] Uses Turbo for navigation (no full page reload)
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-007: Add reminder indicator icon to items
**Description:** As a user, I want to see which items have reminders set so I know at a glance what has upcoming notifications.

**Acceptance Criteria:**
- [ ] Small bell icon displayed on items that have pending reminders
- [ ] Icon positioned consistently (e.g., near item actions or status)
- [ ] Icon only shows for items with at least one pending notification
- [ ] Uses existing Icon component pattern
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-008: Show reminder time on item hover/expand
**Description:** As a user, I want to see when my reminder is set when I hover over or expand an item.

**Acceptance Criteria:**
- [ ] On hover/expand, show next reminder time (e.g., "Reminder: Jan 16, 9:00 AM")
- [ ] If multiple reminders, show "Next: [time]" with count (e.g., "+2 more")
- [ ] Time displayed in user-friendly format
- [ ] Tooltip or inline text depending on item layout
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-009: Add "Reminders" section to item actions sheet
**Description:** As a user, I want to see and manage reminders in the item's actions sheet so I can add or remove reminders.

**Acceptance Criteria:**
- [ ] New "Reminders" section in actions sheet (below existing actions)
- [ ] Section header "Reminders" with "Add" button
- [ ] Lists existing reminders for this item (date/time for each)
- [ ] Each reminder row has delete button (X icon)
- [ ] Empty state shows "No reminders set"
- [ ] Section only visible for items that support reminders (completable items)
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-010: Create add reminder form
**Description:** As a user, I want to add a new reminder by selecting a date and time.

**Acceptance Criteria:**
- [ ] Clicking "Add" in reminders section shows inline form or navigates to form view
- [ ] Form has datetime picker input for reminder time
- [ ] Quick preset buttons: "In 1 hour", "Tomorrow 9am", "In 3 days"
- [ ] "Save" button creates the notification via POST
- [ ] Cancel button returns to reminders list
- [ ] Validation: cannot set reminder in the past
- [ ] Success: reminder appears in list, form closes
- [ ] Uses RubyUI form components per CLAUDE.md rules
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-011: Implement delete reminder functionality
**Description:** As a user, I want to delete a reminder I no longer need.

**Acceptance Criteria:**
- [ ] Delete button (X icon) on each reminder row
- [ ] Clicking delete shows confirmation (RubyUI::AlertDialog per CLAUDE.md)
- [ ] Confirming deletes the notification via DELETE request
- [ ] Reminder removed from list via Turbo Stream
- [ ] Reminder indicator on item updates if no reminders remain
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-012: Create NotificationsController
**Description:** As a developer, I need a controller to handle notification-related actions.

**Acceptance Criteria:**
- [ ] Create `NotificationsController` with actions: index, create, destroy, mark_all_read
- [ ] `index` returns notifications dropdown partial (Turbo Stream)
- [ ] `create` creates notification for item, returns updated reminders section
- [ ] `destroy` deletes notification, returns updated reminders section
- [ ] `mark_all_read` calls service, returns updated bell badge
- [ ] All actions scoped to `current_user`
- [ ] Add routes for all actions
- [ ] Typecheck/lint passes

### US-013: Add Notification Preferences tab to settings modal
**Description:** As a user, I want to configure my notification preferences in the settings modal.

**Acceptance Criteria:**
- [ ] New "Notifications" tab in settings modal
- [ ] Toggle for "Push notifications" (on/off)
- [ ] Toggle for "In-app notifications" (on/off)
- [ ] Quiet hours section with start time and end time inputs
- [ ] "During quiet hours, notifications will be held until the period ends"
- [ ] Save button persists preferences to `user.notification_preferences`
- [ ] Changes saved via Turbo Stream (no page reload)
- [ ] Uses RubyUI form components per CLAUDE.md rules
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

### US-014: Real-time badge updates via Turbo
**Description:** As a user, I want my notification badge to update in real-time when new notifications arrive.

**Acceptance Criteria:**
- [ ] When SendNotificationJob sends a notification, badge count updates
- [ ] Uses Turbo Stream broadcast to user's channel
- [ ] Badge animates briefly when count increases (subtle pulse)
- [ ] Works without page refresh
- [ ] Typecheck/lint passes
- [ ] Verify in browser using dev-browser skill

## Functional Requirements

- FR-1: Display notification bell icon in application header
- FR-2: Show unread notification count as badge on bell icon (0 = hidden, 99+ for overflow)
- FR-3: Click bell to open dropdown panel with notification list
- FR-4: Each notification displays item title, reminder time, and relative timestamp
- FR-5: Click notification to navigate to day, scroll to item, and highlight it
- FR-6: Mark notification as read when clicked
- FR-7: "Mark all read" link marks all notifications read and updates badge
- FR-8: Display bell icon indicator on items with pending reminders
- FR-9: Show reminder time(s) on item hover/expand
- FR-10: Actions sheet "Reminders" section lists all reminders for an item
- FR-11: Add reminder form with datetime picker and quick presets
- FR-12: Delete reminder with confirmation dialog
- FR-13: Notification preferences tab in settings: push toggle, in-app toggle, quiet hours
- FR-14: Real-time badge updates via Turbo broadcast when notifications are sent

## Non-Goals

- No recurring reminder UI (future enhancement)
- No snooze functionality UI (future enhancement)
- No email notification preferences (not supported by backend)
- No notification sound settings
- No notification grouping or collapsing
- No drag-and-drop reordering of reminders

## Design Considerations

### Components to Create
- `Components::NotificationBell` - Header bell with badge
- `Components::NotificationsDropdown` - Dropdown panel
- `Components::NotificationItem` - Individual notification row
- `Components::RemindersList` - List of reminders in actions sheet
- `Components::ReminderForm` - Add reminder form
- `Components::NotificationPreferencesTab` - Settings tab content

### Existing Components to Reuse
- `Icon::Bell` (create if doesn't exist)
- `RubyUI::Badge` for count badge
- `RubyUI::AlertDialog` for delete confirmation
- `RubyUI::Input` with `type: :datetime_local` for datetime picker
- `RubyUI::Form`, `RubyUI::FormField`, etc. per CLAUDE.md
- Actions sheet navigation pattern (replace content, don't create new backdrop)

### Stimulus Controllers
- `notifications` - Dropdown open/close, mark all read
- `reminder-form` - Quick presets, validation
- `item-highlight` - Scroll to and highlight item after navigation

## Technical Considerations

- **Turbo Streams**: Use for all dynamic updates (badge, dropdown, reminders list)
- **Drawer Navigation**: Follow CLAUDE.md rules - reminders section uses `turbo_stream.replace("sheet_content_area")` for navigation within drawer
- **Delete Confirmation**: Must use `RubyUI::AlertDialog`, never `turbo_confirm`
- **Form Components**: All forms must use RubyUI form components per CLAUDE.md
- **Icon Components**: Create `Icon::Bell`, `Icon::BellRing` (for notifications) in `app/components/icon/`
- **Highlight Animation**: Use CSS animation with Stimulus controller to trigger on page load with URL param

## Success Metrics

- Users can add a reminder in under 3 clicks from item
- Unread notification badge accurately reflects count
- Click-to-navigate takes user directly to item within 1 second
- Notification preferences save without page reload
- No duplicate backdrops or broken drawer navigation

## Open Questions

- Should reminders section be visible for all item types or just completable?
- Should there be a "Remind me" quick action in item context menu?
- What should happen to the notification if the item is completed before the reminder fires?
- Should quiet hours display in user's local timezone or allow timezone selection?
