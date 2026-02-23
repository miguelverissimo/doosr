class AgendaPost < ApplicationRecord
  belongs_to :user

  validates :data, presence: true
  validate :data_must_be_valid_schema

  # Subclasses must override this to define required entry fields
  def self.required_entry_fields
    raise NotImplementedError, "Subclasses must define required_entry_fields"
  end

  # Subclasses can override this to define optional entry fields
  def self.optional_entry_fields
    []
  end

  private

  def data_must_be_valid_schema
    return if data.blank?

    unless data.is_a?(Hash) && data["entries"].is_a?(Array)
      errors.add(:data, "must contain an 'entries' array")
      return
    end

    validate_entries(data["entries"])
  end

  def validate_entries(entries)
    entries.each_with_index do |entry, index|
      validate_entry(entry, index)
    end
  end

  def validate_entry(entry, index)
    required = self.class.required_entry_fields
    optional = self.class.optional_entry_fields
    allowed = required + optional

    # Check required fields
    missing = required - entry.keys
    if missing.any?
      errors.add(:data, "entry #{index} missing required fields: #{missing.join(', ')}")
    end

    # Check for unknown fields
    unknown = entry.keys - allowed
    if unknown.any?
      errors.add(:data, "entry #{index} has unknown fields: #{unknown.join(', ')}")
    end
  end
end
