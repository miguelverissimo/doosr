# frozen_string_literal: true

class MigrationOptions
  MIGRATION_OPTIONS = {
    links: { type: :boolean, default: true },
    active_item_sections: { type: :boolean, default: true },
    notes: { type: :boolean, default: false },
    items: {
      sections: { type: :boolean, default: true },
      notes: { type: :boolean, default: true }
    }
  }.freeze

  def self.defaults
    build_defaults(MIGRATION_OPTIONS)
  end

  def self.build_defaults(options)
    options.each_with_object({}) do |(key, value), result|
      if value.is_a?(Hash) && value.key?(:type)
        result[key.to_s] = value[:default]
      elsif value.is_a?(Hash)
        result[key.to_s] = build_defaults(value)
      end
    end
  end
end
