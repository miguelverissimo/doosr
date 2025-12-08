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
  belongs_to :descendant_record, class_name: 'Descendant', foreign_key: 'descendant_id', optional: true

  # Self-referential associations
  belongs_to :source_item, class_name: 'Item', optional: true
  belongs_to :recurring_next_item, class_name: 'Item', optional: true

  # Inverse associations
  has_many :items_imported_from_this, class_name: 'Item', foreign_key: 'source_item_id', dependent: :nullify
  has_many :recurring_previous_items, class_name: 'Item', foreign_key: 'recurring_next_item_id', dependent: :nullify

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

  # State transition methods
  def mark_done!
    return false unless completable?
    update!(state: :done, done_at: Time.current)
  end

  def mark_dropped!
    return false unless completable?
    update!(state: :dropped, dropped_at: Time.current)
  end

  def mark_deferred!(deferred_to_date)
    return false unless completable?
    update!(
      state: :deferred,
      deferred_at: Time.current,
      deferred_to: deferred_to_date
    )
  end

  def mark_todo!
    return false unless completable?
    update!(
      state: :todo,
      done_at: nil,
      dropped_at: nil,
      deferred_at: nil,
      deferred_to: nil
    )
  end

  # Check state
  def completed?
    done?
  end

  def active?
    todo?
  end

  def can_be_completed?
    completable?
  end

  # Nesting support
  def has_nested_items?
    descendant&.active_items&.any? || descendant&.inactive_items&.any?
  end

  def nested_item_count
    return 0 unless descendant
    descendant.active_items.count + descendant.inactive_items.count
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
      when 'done'
        self.done_at = Time.current if done_at.nil?
      when 'dropped'
        self.dropped_at = Time.current if dropped_at.nil?
      when 'deferred'
        self.deferred_at = Time.current if deferred_at.nil?
      when 'todo'
        # Clear completion timestamps when returning to todo
        self.done_at = nil
        self.dropped_at = nil
        self.deferred_at = nil
        self.deferred_to = nil
      end
    end
  end

  def section_cannot_have_completion_state
    if section? && !todo?
      errors.add(:state, "sections can only be in 'todo' state")
    end
  end

  def deferred_to_must_be_future
    if deferred? && deferred_to.present? && deferred_to < Time.current
      errors.add(:deferred_to, "must be in the future")
    end
  end
end
