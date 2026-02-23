class AgendaPost::Appointment < AgendaPost
  REQUIRED_ENTRY_FIELDS = %w[start_time end_time title].freeze
  OPTIONAL_ENTRY_FIELDS = %w[calendar url].freeze

  def self.required_entry_fields
    REQUIRED_ENTRY_FIELDS
  end

  def self.optional_entry_fields
    OPTIONAL_ENTRY_FIELDS
  end

  private

  def validate_entry(entry, index)
    super

    # Validate ISO8601 datetime format for start_time and end_time
    %w[start_time end_time].each do |field|
      next unless entry[field].present?

      begin
        Time.iso8601(entry[field])
      rescue ArgumentError
        errors.add(:data, "entry #{index} #{field} must be valid ISO8601 datetime")
      end
    end

    # Validate end_time is after start_time
    if entry["start_time"].present? && entry["end_time"].present?
      begin
        start_time = Time.iso8601(entry["start_time"])
        end_time = Time.iso8601(entry["end_time"])
        if end_time <= start_time
          errors.add(:data, "entry #{index} end_time must be after start_time")
        end
      rescue ArgumentError
        # Already handled above
      end
    end
  end
end
