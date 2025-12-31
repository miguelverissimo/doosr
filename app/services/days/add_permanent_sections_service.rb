# frozen_string_literal: true

class Days::AddPermanentSectionsService
  # Adds permanent sections to a day, ensuring no duplicates
  #
  # - Idempotent: Safe to call multiple times
  # - Case-insensitive title matching (CRITICAL)
  # - Only adds sections that don't already exist
  # - Creates descendant for each section
  #
  # Returns: { success: Boolean, sections_added: Integer, error: String }

  attr_reader :day, :user

  def initialize(day:, user:)
    @day = day
    @user = user
  end

  def call
    permanent_sections = user.permanent_sections || []
    return { success: true, sections_added: 0 } if permanent_sections.empty?

    sections_added = 0

    ActiveRecord::Base.transaction do
      permanent_sections.each do |section_name|
        # CRITICAL: Case-insensitive check
        next if section_exists_on_day?(section_name)

        # Create section item
        section = user.items.create!(
          title: section_name,
          item_type: :section,
          state: :todo,
          extra_data: { permanent_section: true }
        )

        # Ensure section has a descendant
        section.descendant || section.create_descendant!(active_items: [], inactive_items: [])

        # Add section to day's active items
        day.descendant.add_active_item(section.id)
        day.descendant.save!

        sections_added += 1
      end

      { success: true, sections_added: sections_added }
    end
  rescue StandardError => e
    Rails.logger.error "Add permanent sections failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    { success: false, error: e.message }
  end

  private

  def section_exists_on_day?(section_title)
    return false unless day.descendant

    section_ids = day.descendant.extract_active_item_ids

    # CRITICAL: Case-insensitive matching using LOWER (PostgreSQL)
    Item.sections
        .where(id: section_ids)
        .where("LOWER(title) = ?", section_title.downcase)
        .exists?
  end
end
