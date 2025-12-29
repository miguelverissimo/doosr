# frozen_string_literal: true

# Item represents the core building block of the app.
# Items can be todos, sections, reusable templates, or trackable habits.
#
# Item Types:
# - completable: Standard todo items that can be marked as done/dropped/deferred
# - section: Organizational headers, cannot be completed
# - reusable: Templates that can be reused (e.g., shopping lists)
# - trackable: Habits or metrics to track over time
#
# Item States (for completable items):
# - todo: Active, not yet done
# - done: Completed
# - dropped: Abandoned/cancelled
# - deferred: Postponed to a future date
#
class Item < ApplicationRecord
  # Associations
  belongs_to :user

  # Polymorphic association - this Item can have nested items via Descendant
  has_one :descendant, as: :descendable, dependent: :destroy
  belongs_to :descendant_record, class_name: "Descendant", foreign_key: "descendant_id", optional: true

  # Self-referential associations
  belongs_to :source_item, class_name: "Item", optional: true
  belongs_to :recurring_next_item, class_name: "Item", optional: true

  # Inverse associations
  has_many :items_imported_from_this, class_name: "Item", foreign_key: "source_item_id", dependent: :nullify
  has_many :recurring_previous_items, class_name: "Item", foreign_key: "recurring_next_item_id", dependent: :nullify

  # Enums
  enum :item_type, {
    completable: 0,
    section: 1,
    reusable: 2,
    trackable: 3
  }, default: :completable, validate: true

  enum :state, {
    todo: 0,
    done: 1,
    dropped: 2,
    deferred: 3
  }, default: :todo, validate: true

  # Validations
  validates :title, presence: true
  validates :user, presence: true
  validates :item_type, presence: true
  validates :state, presence: true
  validate :section_cannot_have_completion_state
  validate :deferred_to_must_be_future

  # Callbacks
  after_create :create_descendant_if_needed
  before_update :track_state_changes

  # Scopes
  scope :for_user, ->(user) { where(user: user) }
  scope :completables, -> { where(item_type: :completable) }
  scope :sections, -> { where(item_type: :section) }
  scope :reusables, -> { where(item_type: :reusable) }
  scope :trackables, -> { where(item_type: :trackable) }
  scope :active, -> { where(state: :todo) }
  scope :completed, -> { where(state: :done) }
  scope :ordered_by_creation, -> { order(created_at: :asc) }

  # State transition methods with descendant management
  def set_todo!
    return false unless can_be_completed?

    # If this item has a recurring_next_item, delete it (hard delete)
    delete_next_recurring_item if recurring_next_item_id.present?

    # Find the descendant this item belongs to
    containing_descendant = Descendant.containing_item(id)

    if containing_descendant
      # If already in active items, just update state
      if containing_descendant.active_item?(id)
        update!(state: :todo, done_at: nil, dropped_at: nil, deferred_at: nil, deferred_to: nil)
        return true
      end

      # If in inactive items, move to active items FIRST, then update state
      if containing_descendant.inactive_item?(id)
        containing_descendant.remove_inactive_item(id)
        containing_descendant.add_active_item(id)
        containing_descendant.save!
        update!(state: :todo, done_at: nil, dropped_at: nil, deferred_at: nil, deferred_to: nil)
        return true
      end
    end

    # No descendant or item not in any array - just update state
    update!(state: :todo, done_at: nil, dropped_at: nil, deferred_at: nil, deferred_to: nil)
    true
  end

  def set_done!
    Rails.logger.info "===================================================="
    Rails.logger.info "=== SET DONE CALLED ==="
    Rails.logger.info "Item: #{id}:#{title}"
    Rails.logger.info "Can be completed: #{can_be_completed?}"
    Rails.logger.info "HAS RECURRENCE: #{has_recurrence?}"
    Rails.logger.info "RECURRENCE RULE: #{recurrence_rule.inspect}"
    Rails.logger.info "===================================================="
    return false unless can_be_completed?

    # Find the descendant this item belongs to
    containing_descendant = Descendant.containing_item(id)

    if containing_descendant
      Rails.logger.debug "Containing descendant: #{containing_descendant.id}"
      Rails.logger.debug "Active items: #{containing_descendant.active_items.inspect}"
      Rails.logger.debug "Inactive items: #{containing_descendant.inactive_items.inspect}"
      # If already in inactive items, just update state
      if containing_descendant.inactive_item?(id)
        Rails.logger.info "=== ALREADY IN INACTIVE ITEMS ==="
        update!(state: :done, done_at: Time.current)
        Rails.logger.info ">>> ABOUT TO CHECK RECURRENCE: has_recurrence?=#{has_recurrence?}"
        if has_recurrence?
          Rails.logger.info ">>> CALLING schedule_next_recurrence"
          schedule_next_recurrence
        else
          Rails.logger.info ">>> NOT CALLING schedule_next_recurrence (no recurrence)"
        end
        return true
      end

      # If in active items, move to inactive items FIRST, then update state
      if containing_descendant.active_item?(id)
        Rails.logger.info "=== IN ACTIVE ITEMS ==="
        containing_descendant.remove_active_item(id)
        containing_descendant.add_inactive_item(id)
        containing_descendant.save!

        Rails.logger.info "Descendant state after move:"
        Rails.logger.info "Active items: #{containing_descendant.active_items.inspect}"
        Rails.logger.info "Inactive items: #{containing_descendant.inactive_items.inspect}"
        update!(state: :done, done_at: Time.current)
        Rails.logger.info ">>> ABOUT TO CHECK RECURRENCE: has_recurrence?=#{has_recurrence?}"
        if has_recurrence?
          Rails.logger.info ">>> CALLING schedule_next_recurrence"
          schedule_next_recurrence
        else
          Rails.logger.info ">>> NOT CALLING schedule_next_recurrence (no recurrence)"
        end
        return true
      end
    end

    # No descendant or item not in any array - just update state
    Rails.logger.info "=== NO DESCENDANT OR NOT IN ARRAY ==="
    update!(state: :done, done_at: Time.current)
    Rails.logger.info ">>> ABOUT TO CHECK RECURRENCE: has_recurrence?=#{has_recurrence?}"
    if has_recurrence?
      Rails.logger.info ">>> CALLING schedule_next_recurrence"
      schedule_next_recurrence
    else
      Rails.logger.info ">>> NOT CALLING schedule_next_recurrence (no recurrence)"
    end
    true
  end

  def set_dropped!
    return false unless can_be_completed?

    # Find the descendant this item belongs to
    containing_descendant = Descendant.containing_item(id)

    if containing_descendant
      # If already in inactive items, just update state
      if containing_descendant.inactive_item?(id)
        update!(state: :dropped, dropped_at: Time.current)
        return true
      end

      # If in active items, move to inactive items FIRST, then update state
      if containing_descendant.active_item?(id)
        containing_descendant.remove_active_item(id)
        containing_descendant.add_inactive_item(id)
        containing_descendant.save!
        update!(state: :dropped, dropped_at: Time.current)
        return true
      end
    end

    # No descendant or item not in any array - just update state
    update!(state: :dropped, dropped_at: Time.current)
    true
  end

  def set_deferred!(deferred_to_date)
    return false unless can_be_completed?

    # Find the descendant this item belongs to
    containing_descendant = Descendant.containing_item(id)

    if containing_descendant
      # If already in inactive items, just update state
      if containing_descendant.inactive_item?(id)
        update!(state: :deferred, deferred_at: Time.current, deferred_to: deferred_to_date)
        return true
      end

      # If in active items, move to inactive items FIRST, then update state
      if containing_descendant.active_item?(id)
        containing_descendant.remove_active_item(id)
        containing_descendant.add_inactive_item(id)
        containing_descendant.save!
        update!(state: :deferred, deferred_at: Time.current, deferred_to: deferred_to_date)
        return true
      end
    end

    # No descendant or item not in any array - just update state
    update!(state: :deferred, deferred_at: Time.current, deferred_to: deferred_to_date)
    true
  end

  # Legacy methods - keep for backwards compatibility but use new methods
  def mark_todo!
    set_todo!
  end

  def mark_done!
    set_done!
  end

  def mark_dropped!
    set_dropped!
  end

  def mark_deferred!(deferred_to_date)
    set_deferred!(deferred_to_date)
  end

  # Check state
  def completed?
    done?
  end

  def active?
    todo?
  end

  def can_be_completed?
    completable? || reusable?
  end

  # Nesting support
  def has_nested_items?
    descendant&.active_items&.any? || descendant&.inactive_items&.any?
  end

  def nested_item_count
    return 0 unless descendant
    descendant.extract_active_item_ids.count + descendant.extract_inactive_item_ids.count
  end

  # Import from source item
  def import_from!(source)
    update!(
      source_item: source,
      title: source.title,
      item_type: source.item_type,
      extra_data: source.extra_data
    )
  end

  # Find deferred copy of this item
  # Returns the item that was created when this item was deferred
  # Should only ever return 0 or 1 item
  # Note: The copy might have been modified by the user (e.g., completed), so we don't filter by state
  def find_deferred_copy
    items_imported_from_this.first
  end

  # Find all copies (for validation/debugging)
  def find_all_copies
    items_imported_from_this
  end

  # Find which permanent section (if any) this item belongs to
  # Returns the permanent section Item, or nil
  def find_permanent_section
    Items::FindPermanentSectionService.new(item: self).call
  end

  # Recurrence support
  def has_recurrence?
    recurrence_rule.present?
  end

  def create_next_recurring_item!
    return nil unless has_recurrence?

    next_item = user.items.create!(
      title: title,
      item_type: item_type,
      recurrence_rule: recurrence_rule,
      extra_data: extra_data
    )

    update!(recurring_next_item: next_item)
    next_item
  end

  # Date calculation utilities for deferring
  # All dates normalized to midnight UTC (matches day dateKey format)
  def self.get_tomorrow_date
    (Date.today + 1.day).beginning_of_day
  end

  def self.get_next_monday_date
    today = Date.today
    days_until_monday = (8 - today.wday) % 7
    days_until_monday = 7 if days_until_monday == 0 # If today is Monday, go to next Monday
    (today + days_until_monday.days).beginning_of_day
  end

  def self.get_next_month_first_date
    (Date.today.next_month.beginning_of_month).beginning_of_day
  end

  private

  def create_descendant_if_needed
    # Only sections and reusables can have nested items by default
    return unless section? || reusable?
    return if descendant.present?
    build_descendant.save!
  end

  def track_state_changes
    if state_changed?
      case state
      when "done"
        self.done_at = Time.current if done_at.nil?
      when "dropped"
        self.dropped_at = Time.current if dropped_at.nil?
      when "deferred"
        self.deferred_at = Time.current if deferred_at.nil?
      when "todo"
        # Clear completion timestamps when returning to todo
        self.done_at = nil
        self.dropped_at = nil
        self.deferred_at = nil
        self.deferred_to = nil
      end
    end
  end

  def section_cannot_have_completion_state
    # Only sections and trackables cannot have completion states
    if (section? || trackable?) && !todo?
      errors.add(:state, "#{item_type} items can only be in 'todo' state")
    end
  end

  def deferred_to_must_be_future
    if deferred? && deferred_to.present? && deferred_to.to_date < Date.today
      errors.add(:deferred_to, "must be today or in the future")
    end
  end

  # Schedule the next recurrence when this item is completed
  def schedule_next_recurrence
    Rails.logger.info "=== SCHEDULING NEXT RECURRENCE ==="
    Rails.logger.info "Item ID: #{id}, Title: #{title}"
    Rails.logger.info "has_recurrence?: #{has_recurrence?}"
    Rails.logger.info "recurrence_rule: #{recurrence_rule.inspect}"

    return unless has_recurrence?

    result = Items::ScheduleNextOccurrenceService.new(
      completed_item: self,
      user: user
    ).call

    if result[:success]
      Rails.logger.info "✓ Successfully scheduled next recurrence for item #{id}"
      Rails.logger.info "  New item ID: #{result[:new_item].id}"
      Rails.logger.info "  New item title: #{result[:new_item].title}"
      Rails.logger.info "  Target date: #{result[:new_item].id}"
    else
      Rails.logger.error "✗ Failed to schedule next recurrence for item #{id}: #{result[:error]}"
    end
    Rails.logger.info "=== END SCHEDULING NEXT RECURRENCE ==="
  end

  # Delete the next recurring item (hard delete)
  def delete_next_recurring_item
    return unless recurring_next_item_id.present?

    next_item = Item.find_by(id: recurring_next_item_id)
    return unless next_item

    # Find the descendant containing this item and remove it
    containing_descendant = Descendant.containing_item(next_item.id)
    if containing_descendant
      containing_descendant.remove_active_item(next_item.id) if containing_descendant.active_item?(next_item.id)
      containing_descendant.remove_inactive_item(next_item.id) if containing_descendant.inactive_item?(next_item.id)
      containing_descendant.save!
    end

    # Hard delete the item
    next_item.destroy!

    # Clear the link
    update_column(:recurring_next_item_id, nil)

    Rails.logger.debug "Deleted next recurring item #{next_item.id} for item #{id}"
  end
end
