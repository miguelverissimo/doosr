# frozen_string_literal: true

module Days
  class DayMigrationService
    # Service for migrating items from a source day to a target day
    # Handles permanent sections matching and uses CopyToDescendantService for recursive copying
    #
    # Returns: { success: Boolean, target_day: Day, migrated_count: Integer }

    attr_reader :user, :source_day, :target_date, :migration_settings

    def initialize(user:, source_day:, target_date:, migration_settings: {})
      @user = user
      @source_day = source_day
      @target_date = target_date
      @migration_settings = migration_settings
    end

    def call
      ActiveRecord::Base.transaction do
        # CRITICAL: Check if source day has already been migrated from
        if source_day.imported_to_day_id.present?
          existing_target = Day.find_by(id: source_day.imported_to_day_id)
          if existing_target
            raise StandardError, "This day has already been migrated to #{existing_target.date.strftime('%Y-%m-%d')}. Cannot migrate again."
          end
        end

        # Ensure target day exists with permanent sections
        target_day = ensure_target_day_exists

        # Get items to migrate from source day
        source_items = collect_items_to_migrate

        # Migrate items, handling permanent section matching
        migrated_count = migrate_items(source_items, target_day)

        # Migrate list links from source day to target day
        migrate_list_links(target_day)

        # CRITICAL: Mark migration chain
        source_day.update!(
          imported_to_day_id: target_day.id,
          imported_at: Time.current
        )

        target_day.update!(
          imported_from_day_id: source_day.id,
          imported_at: Time.current
        )

        { success: true, target_day: target_day, migrated_count: migrated_count }
      end
    rescue StandardError => e
      Rails.logger.error "Day migration failed: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      { success: false, error: e.message }
    end

    private

    def ensure_target_day_exists
      # Use unified day opening service
      result = Days::DayOpeningService.new(user: user, date: target_date).call
      raise StandardError, result[:error] unless result[:success]

      result[:day]
    end

    def collect_items_to_migrate
      return [] unless source_day.descendant

      # Get all active items from source day
      active_item_ids = source_day.descendant.extract_active_item_ids
      # Use sanitize_sql to prevent SQL injection
      order_sql = ActiveRecord::Base.sanitize_sql_array(
        [ "array_position(ARRAY[?]::bigint[], id)", active_item_ids.map(&:to_i) ]
      )
      Item.where(id: active_item_ids).order(Arel.sql(order_sql))
    end

    def migrate_items(source_items, target_day)
      migrated_count = 0

      # Build map of permanent sections in target day (these should already exist)
      permanent_section_map = build_permanent_section_map(target_day)

      # PASS 1: Migrate permanent section children
      # Find permanent sections in source and migrate their children to matching sections in target
      source_items.each do |source_item|
        if is_permanent_section?(source_item)
          migrate_permanent_section_children(source_item, permanent_section_map, target_day)
          # NOTE: We do NOT increment migrated_count for permanent sections themselves
          # because they already exist in target day and we're only migrating their children
        end
      end

      # PASS 2: Migrate all non-permanent items
      # These go to the root of the target day
      source_items.each do |source_item|
        # Skip permanent sections - they were handled in Pass 1
        next if is_permanent_section?(source_item)

        # Check if this item should be migrated based on settings and state
        if should_migrate_item?(source_item)
          result = Items::CopyToDescendantService.new(
            source_item: source_item,
            target_descendant: target_day.descendant,
            user: user,
            copy_settings: migration_settings.dig("items") || {}
          ).call

          migrated_count += 1 if result[:success]
        end
      end

      target_day.descendant.save!
      migrated_count
    end

    def build_permanent_section_map(target_day)
      return {} unless target_day.descendant

      map = {}
      active_item_ids = target_day.descendant.extract_active_item_ids
      items = Item.where(id: active_item_ids)

      items.each do |item|
        if item.item_type == "section" && item.extra_data&.dig("permanent_section")
          map[item.title] = item
        end
      end

      map
    end

    def is_permanent_section?(item)
      item.item_type == "section" && item.extra_data&.dig("permanent_section")
    end

    def migrate_permanent_section_children(source_section, permanent_section_map, target_day)
      target_section = permanent_section_map[source_section.title]
      return unless target_section

      # Get children from source section (ONLY active items - inactive items NEVER get migrated)
      return unless source_section.descendant

      source_child_ids = source_section.descendant.extract_active_item_ids
      source_children = Item.where(id: source_child_ids)

      # Ensure target section has descendant
      target_section.descendant || target_section.create_descendant!

      # Copy each child to target section
      # CRITICAL: Check if item should be migrated before copying (state filtering)
      source_children.each do |child_item|
        # CRITICAL: NEVER migrate permanent sections - they should not be nested
        # If we find one, skip it to prevent duplicates
        next if is_permanent_section?(child_item)

        # CRITICAL: Only copy items that pass the should_migrate_item? check
        next unless should_migrate_item?(child_item)

        Items::CopyToDescendantService.new(
          source_item: child_item,
          target_descendant: target_section.descendant,
          user: user,
          copy_settings: migration_settings.dig("items") || {}
        ).call
      end
    end

    def should_migrate_item?(item)
      # CRITICAL: Completable items ONLY migrate if they are in 'todo' state
      return false if item.item_type == "completable" && item.state != "todo"

      # CRITICAL: All non-section items must be in 'todo' state to migrate
      unless item.item_type == "section"
        return item.state == "todo"
      end

      # For non-permanent sections, check the active_item_sections setting
      if item.item_type == "section" && !is_permanent_section?(item)
        return migration_settings.dig("active_item_sections") != false
      end

      true
    end

    def migrate_list_links(target_day)
      # Get list links from source day
      source_list_ids = source_day.descendant.extract_active_ids_by_type("List")
      return if source_list_ids.empty?

      # Add each list link to target day (only if user still has access and list still exists)
      source_list_ids.each do |list_id|
        list = user.lists.find_by(id: list_id)
        next unless list

        # Add to target day if not already present
        unless target_day.descendant.active_record?("List", list_id)
          target_day.descendant.add_active_record("List", list_id)
        end
      end

      target_day.descendant.save!
    end
  end
end
