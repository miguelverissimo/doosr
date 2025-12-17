# frozen_string_literal: true

class MigrationOptions
  MIGRATION_OPTIONS = {
    links: {
      type: :boolean,
      default: true,
      label: "Migrate Links",
      description: "Include links when importing from previous day"
    },
    notes: {
      type: :boolean,
      default: false,
      label: "Migrate Notes",
      description: "Include notes when importing"
    },
    items: {
      label: "Per Item Settings",
      sections_with_no_active_items: {
        type: :boolean,
        default: true,
        label: "Migrate Empty Sections",
        description: "Migrate sections even when they have no active items (inactive items are never migrated)"
      },
      notes: {
        type: :boolean,
        default: true,
        label: "Migrate Item Notes",
        description: "Include notes within items"
      }
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

  # Returns an array of top-level options (non-nested) for form rendering
  def self.top_level_options
    MIGRATION_OPTIONS.reject { |_k, v| v.is_a?(Hash) && !v.key?(:type) }
  end

  # Returns nested option groups (like "items") for form rendering
  def self.nested_option_groups
    MIGRATION_OPTIONS.select { |_k, v| v.is_a?(Hash) && !v.key?(:type) }
  end

  # Returns options within a nested group
  def self.options_for_group(group_key)
    group = MIGRATION_OPTIONS[group_key]
    return {} unless group.is_a?(Hash)

    group.reject { |k, _v| k == :label }
  end
end
