# PRD: Item Notifications (Backend/Data Model)

## Introduction

Add the ability for users to set time-based reminders on items. When the reminder time arrives, users receive both a Web Push notification (browser) and an in-app notification (bell icon with unread count). This PRD covers the backend data model and infrastructure only; UI implementation will follow in a separate PRD.

## Goals

- Store notification/reminder data associated with items
- Support scheduling reminders for specific date/time
- Track notification delivery status (pending, sent, read, dismissed)
- Support both Web Push and in-app notification channels
- Enable users to have multiple reminders per item
- Provide foundation for future notification features (recurring, snooze)

## User Stories

### US-001: Create Notification model and migration
**Description:** As a developer, I need a database model to store notification data so reminders can be scheduled and tracked.

**Acceptance Criteria:**
- [ ] Create `Notification` model with fields:
  - `user_id` (references users, not null)
  - `item_id` (references items, not null)
  - `remind_at` (datetime, not null) - when to send the notification
  - `title` (string) - notification title (auto-generated from item)
  - `body` (text) - notification body (optional custom message)
  - `status` (string, default: 'pending') - pending/sent/read/dismissed
  - `sent_at` (datetime, null) - when notification was actually sent
  - `read_at` (datetime, null) - when user read/acknowledged it
  - `channels` (string array, default: ['push', 'in_app']) - delivery channels
  - `metadata` (jsonb, default: {}) - for future extensibility
- [ ] Add database indexes on `user_id`, `item_id`, `status`, and `remind_at`
- [ ] Add compound index on `(status, remind_at)` for efficient job queries
- [ ] Migration runs successfully
- [ ] Typecheck/lint passes

### US-002: Add model validations and associations
**Description:** As a developer, I need proper validations and associations so data integrity is maintained.

**Acceptance Criteria:**
- [ ] `Notification` belongs to `User` and `Item`
- [ ] `User` has many `notifications`
- [ ] `Item` has many `notifications` (with dependent: :destroy)
- [ ] Validate presence of `user_id`, `item_id`, `remind_at`
- [ ] Validate `status` is one of: pending, sent, read, dismissed
- [ ] Validate `remind_at` is in the future (on create only)
- [ ] Validate `channels` contains only valid values: push, in_app
- [ ] Scope `pending` returns notifications where status is pending
- [ ] Scope `due` returns pending notifications where remind_at <= Time.current
- [ ] Scope `unread` returns sent notifications where read_at is nil
- [ ] Scope `for_user(user)` returns notifications for a specific user
- [ ] Typecheck/lint passes

### US-003: Create notification status transition methods
**Description:** As a developer, I need clean methods to transition notification status so state changes are consistent.

**Acceptance Criteria:**
- [ ] `mark_sent!` sets status to 'sent' and sent_at to current time
- [ ] `mark_read!` sets status to 'read' and read_at to current time
- [ ] `mark_dismissed!` sets status to 'dismissed'
- [ ] `cancel!` destroys the notification if still pending
- [ ] Status transitions are idempotent (calling twice doesn't error)
- [ ] Typecheck/lint passes

### US-004: Create SendNotificationJob for processing due notifications
**Description:** As a developer, I need a background job that processes due notifications so reminders are sent on time.

**Acceptance Criteria:**
- [ ] Create `SendNotificationJob` that:
  - Finds all due pending notifications
  - For each notification, sends to configured channels
  - Marks notification as sent after successful delivery
  - Handles failures gracefully (logs error, doesn't mark as sent)
- [ ] Job is idempotent (safe to run multiple times)
- [ ] Job scheduled to run every minute via Solid Queue recurring schedule
- [ ] Typecheck/lint passes

### US-005: Integrate Web Push delivery
**Description:** As a developer, I need notifications to be delivered via Web Push so users get browser notifications.

**Acceptance Criteria:**
- [ ] Create `Notifications::WebPushDeliveryService` that:
  - Takes a notification record
  - Builds Web Push payload (title, body, icon, click action)
  - Sends to all user's registered push subscriptions
  - Returns success/failure status
- [ ] Uses existing VAPID configuration
- [ ] Click action opens the relevant day/item
- [ ] Handles expired/invalid subscriptions (removes them)
- [ ] Typecheck/lint passes

### US-006: Create in-app notification infrastructure
**Description:** As a developer, I need in-app notifications stored and queryable so the UI can display them.

**Acceptance Criteria:**
- [ ] `User#unread_notifications_count` returns count of unread notifications
- [ ] `User#unread_notifications` returns unread notifications ordered by sent_at desc
- [ ] Create `Notifications::MarkAllReadService` to mark all user notifications as read
- [ ] Notifications include reference to source item for navigation
- [ ] Typecheck/lint passes

### US-007: Add notification preferences to User model
**Description:** As a developer, I need user preferences for notifications so users can control their experience.

**Acceptance Criteria:**
- [ ] Add `notification_preferences` jsonb column to users (default: {})
- [ ] Preferences include:
  - `push_enabled` (boolean, default: true)
  - `in_app_enabled` (boolean, default: true)
  - `quiet_hours_start` (time, optional)
  - `quiet_hours_end` (time, optional)
- [ ] Create `User#notification_preference(key)` helper method
- [ ] Delivery services respect user preferences
- [ ] Migration runs successfully
- [ ] Typecheck/lint passes

### US-008: Handle item deletion cascade
**Description:** As a developer, I need notifications cleaned up when items are deleted so there are no orphaned records.

**Acceptance Criteria:**
- [ ] Deleting an item destroys all associated notifications
- [ ] Pending notifications are cancelled (not sent)
- [ ] Test confirms cascade works correctly
- [ ] Typecheck/lint passes

## Functional Requirements

- FR-1: Create `notifications` table with user_id, item_id, remind_at, title, body, status, sent_at, read_at, channels, and metadata fields
- FR-2: Notifications belong to User and Item with proper foreign key constraints
- FR-3: Status field must be one of: pending, sent, read, dismissed
- FR-4: Channels field is an array supporting: push, in_app
- FR-5: Background job runs every minute to process due notifications
- FR-6: Web Push delivery uses existing VAPID infrastructure
- FR-7: In-app notifications are queryable by user with unread count
- FR-8: User preferences control which channels are active
- FR-9: Quiet hours prevent notifications during specified time window
- FR-10: Deleting an item cascades to delete its notifications

## Non-Goals

- No UI for creating/editing notifications (separate PRD)
- No recurring notifications (future enhancement)
- No snooze functionality (future enhancement)
- No email notifications (out of scope)
- No notifications for shared/public list items
- No notification grouping or batching
- No notification templates or categories

## Technical Considerations

- **Solid Queue**: Use recurring schedule for the notification job (runs every minute)
- **VAPID**: Web Push infrastructure already exists per tech stack
- **Time Zones**: Store remind_at in UTC, convert to user timezone for display
- **Indexing**: Compound index on (status, remind_at) critical for job performance
- **Idempotency**: Job must handle being run multiple times without duplicate sends
- **Push Subscriptions**: Assume existing `PushSubscription` model exists (or create if needed)

## Database Schema

```ruby
create_table :notifications do |t|
  t.references :user, null: false, foreign_key: true
  t.references :item, null: false, foreign_key: true
  t.datetime :remind_at, null: false
  t.string :title
  t.text :body
  t.string :status, default: 'pending', null: false
  t.datetime :sent_at
  t.datetime :read_at
  t.string :channels, array: true, default: ['push', 'in_app']
  t.jsonb :metadata, default: {}

  t.timestamps
end

add_index :notifications, :user_id
add_index :notifications, :item_id
add_index :notifications, :status
add_index :notifications, :remind_at
add_index :notifications, [:status, :remind_at]
```

## Success Metrics

- Notifications table created with all required fields and indexes
- Background job processes due notifications within 1 minute of remind_at
- Web Push delivery succeeds for valid subscriptions
- In-app notification count accurately reflects unread notifications
- No orphaned notifications after item deletion
- All tests pass

## Open Questions

- Does a `PushSubscription` model already exist, or does it need to be created?
- Should we limit the number of notifications per item (e.g., max 5)?
- Should we add a `notification_sound` preference for Web Push?
- How long should dismissed notifications be retained before cleanup?
