class Checklist < ApplicationRecord
  belongs_to :user
  belongs_to :template, class_name: "Checklist", optional: true

  enum :kind, { template: "template", checklist: "checklist" }, default: :template, validate: true
  enum :flow, { sequential: "sequential", parallel: "parallel" }, default: :sequential, validate: true

  validates :name, presence: true
  validates :description, presence: true
  validates :kind, presence: true
  validates :flow, presence: true

  # Override getter to ensure items is always an array
  def items
    value = read_attribute(:items)
    return [] if value.nil?
    return value if value.is_a?(Array)

    if value.is_a?(String)
      begin
        parsed = JSON.parse(value)
        return parsed if parsed.is_a?(Array)
        return []
      rescue JSON::ParserError
        return []
      end
    end

    []
  end

  # Override getter to ensure metadata is always a hash
  def metadata
    value = read_attribute(:metadata)
    return {} if value.nil?
    return value if value.is_a?(Hash)

    if value.is_a?(String)
      begin
        parsed = JSON.parse(value)
        return parsed if parsed.is_a?(Hash)
        return {}
      rescue JSON::ParserError
        return {}
      end
    end

    {}
  end
end
