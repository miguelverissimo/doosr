class AgendaPost::StudyPlan < AgendaPost
  REQUIRED_ENTRY_FIELDS = %w[subject title].freeze
  OPTIONAL_ENTRY_FIELDS = %w[url].freeze

  def self.required_entry_fields
    REQUIRED_ENTRY_FIELDS
  end

  def self.optional_entry_fields
    OPTIONAL_ENTRY_FIELDS
  end
end
