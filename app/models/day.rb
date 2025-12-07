# frozen_string_literal: true

# Day represents a single day for a user, containing their tasks and activities.
# Each user can have one Day per date.
#
# States:
# - open: Day is active and can be edited
# - closed: Day is archived/completed
#
# Import tracking:
# - Days can be imported from other days, creating a chain of imports
# - imported_from_day: the Day that this Day was created from
# - imported_to_day: the Day that was created from this Day
#
class Day < ApplicationRecord
  # Associations
  belongs_to :user

  # Polymorphic association - this Day has one Descendant for ordering items
  has_one :descendant, as: :descendable, dependent: :destroy

  # Self-referential associations for import tracking
  belongs_to :imported_from_day, class_name: 'Day', optional: true
  belongs_to :imported_to_day, class_name: 'Day', optional: true

  # Inverse associations for import tracking
  has_many :days_imported_from_this, class_name: 'Day', foreign_key: 'imported_from_day_id', dependent: :nullify
  has_many :days_that_imported_this, class_name: 'Day', foreign_key: 'imported_to_day_id', dependent: :nullify

  # Enums
  enum :state, { open: 0, closed: 1 }, default: :open, validate: true

  # Validations
  validates :date, presence: true, uniqueness: { scope: :user_id, message: "already exists for this user" }
  validates :user, presence: true
  validates :state, presence: true

  # Scopes
  scope :open_days, -> { where(state: :open) }
  scope :closed_days, -> { where(state: :closed) }
  scope :for_date, ->(date) { where(date: date) }
  scope :for_user, ->(user) { where(user: user) }
  scope :ordered_by_date, -> { order(date: :desc) }

  # Callbacks
  after_create :create_descendant
  before_update :track_state_changes

  # Close this Day
  def close!
    update!(state: :closed, closed_at: Time.current)
  end

  # Reopen this Day
  def reopen!
    update!(state: :open, reopened_at: Time.current, closed_at: nil)
  end

  # Check if this Day is open
  def open?
    state == 'open'
  end

  # Check if this Day is closed
  def closed?
    state == 'closed'
  end

  # Import from another Day
  # This creates a relationship showing this Day was created/imported from another
  def import_from!(source_day)
    update!(
      imported_from_day: source_day,
      imported_at: Time.current
    )
    source_day.update!(imported_to_day: self)
  end

  # Get the chain of Days this was imported from
  def import_chain_from
    chain = []
    current_day = imported_from_day
    while current_day.present?
      chain << current_day
      current_day = current_day.imported_from_day
    end
    chain
  end

  # Get the chain of Days imported to from this Day
  def import_chain_to
    chain = []
    current_day = imported_to_day
    while current_day.present?
      chain << current_day
      current_day = current_day.imported_to_day
    end
    chain
  end

  # Check if this Day was imported
  def imported?
    imported_from_day.present?
  end

  # Check if this Day has been used as a source for import
  def has_been_imported?
    imported_to_day.present?
  end

  # Human-readable date format
  def formatted_date
    date.strftime('%B %d, %Y')
  end

  # Short date format
  def short_date
    date.strftime('%b %d, %Y')
  end

  private

  def create_descendant
    self.descendant || build_descendant.save!
  end

  def track_state_changes
    if state_changed?
      case state
      when 'closed'
        self.closed_at = Time.current if closed_at.nil?
      when 'open'
        self.reopened_at = Time.current if reopened_at.nil?
      end
    end
  end
end
