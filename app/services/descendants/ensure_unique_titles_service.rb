# frozen_string_literal: true

class Descendants::EnsureUniqueTitlesService
  # Ensures no duplicate titles (case-insensitive) in a descendant's active_items
  #
  # Strategy: Keep first occurrence, remove duplicates
  # Returns: { success: Boolean, removed_count: Integer, duplicates: Array }

  attr_reader :descendant

  def initialize(descendant:)
    @descendant = descendant
  end

  def call
    return { success: true, removed_count: 0, duplicates: [] } unless descendant

    ActiveRecord::Base.transaction do
      active_item_ids = descendant.extract_active_item_ids
      items = Item.where(id: active_item_ids).index_by(&:id)

      seen_titles = Set.new
      duplicates = []
      kept_ids = []

      active_item_ids.each do |item_id|
        item = items[item_id]
        next unless item

        title_lower = item.title.downcase

        if seen_titles.include?(title_lower)
          duplicates << { id: item_id, title: item.title }
        else
          seen_titles.add(title_lower)
          kept_ids << item_id
        end
      end

      # Update descendant with deduplicated list
      if duplicates.any?
        descendant.active_items = kept_ids.map { |id| { "Item" => id } }
        descendant.save!
      end

      { success: true, removed_count: duplicates.length, duplicates: duplicates }
    end
  rescue StandardError => e
    Rails.logger.error "Ensure unique titles failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    { success: false, error: e.message }
  end
end
