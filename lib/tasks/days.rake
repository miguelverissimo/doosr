# frozen_string_literal: true

namespace :days do
  desc "Nuke a day and all its items, descendants, and references"
  task :nuke, [:email, :date] => :environment do |_t, args|
    email = args[:email]
    date_str = args[:date]

    unless email && date_str
      puts "Usage: rake days:nuke['user@example.com','2025-11-20']"
      exit 1
    end

    # Look up user by email
    user = User.find_by(email: email)
    unless user
      puts "Error: User with email '#{email}' not found"
      exit 1
    end

    # Parse date
    begin
      date = Date.parse(date_str)
    rescue ArgumentError
      puts "Error: Invalid date format '#{date_str}'. Use YYYY-MM-DD format."
      exit 1
    end

    # Find day for given date and user
    day = user.days.find_by(date: date)
    unless day
      puts "Error: No day found for user '#{email}' on date '#{date}'"
      exit 1
    end

    # Recursively collect all descendants and items starting from day's descendant
    descendants_to_delete = []
    items_to_delete = []

    def collect_descendants_and_items(descendant, user_id, descendants_array, items_array)
      return unless descendant

      # Add this descendant to deletion list
      descendants_array << descendant

      # Get all item IDs from this descendant
      all_item_ids = descendant.active_items + descendant.inactive_items

      # Fetch items with user_id filtering for safety
      items = Item.where(id: all_item_ids, user_id: user_id).includes(:descendant)

      items.each do |item|
        # Add item to deletion list
        items_array << item

        # Recursively collect from item's descendant if it exists
        if item.descendant
          collect_descendants_and_items(item.descendant, user_id, descendants_array, items_array)
        end
      end
    end

    # Start collection from day's descendant
    if day.descendant
      collect_descendants_and_items(day.descendant, user.id, descendants_to_delete, items_to_delete)
    end

    # Collect item IDs for reference cleanup
    item_ids_to_delete = items_to_delete.map(&:id)

    # Find items that reference items being deleted
    items_with_source_references = Item.where(source_item_id: item_ids_to_delete)
    items_with_recurring_references = Item.where(recurring_next_item_id: item_ids_to_delete)

    # Find days that reference this day in import relationships
    days_imported_from_this = Day.where(imported_from_day_id: day.id)
    days_that_imported_this = Day.where(imported_to_day_id: day.id)

    # Show summary
    puts "Found day for #{email} on #{date}"
    puts "  Day ID: #{day.id}"
    puts "  Day state: #{day.state}"
    puts "  Imported from: #{day.imported_from_day&.date || 'N/A'}"
    puts "  Imported to: #{day.imported_to_day&.date || 'N/A'}"
    puts ""
    puts "Will delete:"
    puts "  #{items_to_delete.count} items"
    puts "  #{descendants_to_delete.count} descendants"
    puts "  1 day"
    puts ""
    puts "Will clear references:"
    puts "  #{items_with_source_references.count} items with source_item_id pointing to deleted items"
    puts "  #{items_with_recurring_references.count} items with recurring_next_item_id pointing to deleted items"
    puts "  #{days_imported_from_this.count} days that were imported from this day"
    puts "  #{days_that_imported_this.count} days that imported to this day"
    puts ""

    # Show first few items as sample
    if items_to_delete.any?
      puts "Sample items to delete (first 5):"
      items_to_delete.first(5).each do |item|
        puts "  - [#{item.id}] #{item.title} (#{item.item_type}, #{item.state})"
      end
      puts "  ... and #{items_to_delete.count - 5} more" if items_to_delete.count > 5
      puts ""
    end

    # Prompt for confirmation
    print "Are you sure you want to NUKE this day? This cannot be undone! (y/n): "
    confirmation = STDIN.gets.chomp.downcase

    unless confirmation == 'y'
      puts "Aborting."
      exit 0
    end

    # Perform deletion in a transaction
    ActiveRecord::Base.transaction do
      # Clear source_item_id references
      items_with_source_references.update_all(source_item_id: nil)
      puts "Cleared source_item_id from #{items_with_source_references.count} items"

      # Clear recurring_next_item_id references
      items_with_recurring_references.update_all(recurring_next_item_id: nil)
      puts "Cleared recurring_next_item_id from #{items_with_recurring_references.count} items"

      # Clear import relationships from days
      days_imported_from_this.update_all(imported_from_day_id: nil, imported_at: nil)
      puts "Cleared import relationships from #{days_imported_from_this.count} days"

      days_that_imported_this.update_all(imported_to_day_id: nil)
      puts "Cleared import relationships from #{days_that_imported_this.count} days"

      # Delete all items
      items_to_delete.each(&:destroy!)
      puts "Deleted #{items_to_delete.count} items"

      # Delete all descendants
      descendants_to_delete.each(&:destroy!)
      puts "Deleted #{descendants_to_delete.count} descendants"

      # Delete the day
      day.destroy!
      puts "Deleted day"

      puts ""
      puts "Successfully NUKED day for #{email} on #{date}"
    end
  end

  desc "Undo import for a specific day"
  task :undo_import, [:email, :date] => :environment do |_t, args|
    email = args[:email]
    date_str = args[:date]

    unless email && date_str
      puts "Usage: rake days:undo_import['user@example.com','2025-11-20']"
      exit 1
    end

    # Look up user by email
    user = User.find_by(email: email)
    unless user
      puts "Error: User with email '#{email}' not found"
      exit 1
    end

    # Parse date
    begin
      date = Date.parse(date_str)
    rescue ArgumentError
      puts "Error: Invalid date format '#{date_str}'. Use YYYY-MM-DD format."
      exit 1
    end

    # Find day for given date and user
    day = user.days.find_by(date: date)
    unless day
      puts "Error: No day found for user '#{email}' on date '#{date}'"
      exit 1
    end

    # Recursively collect all descendants starting from day's descendant
    descendants_to_delete = []
    items_to_delete = []

    def collect_descendants_and_items(descendant, user_id, descendants_array, items_array)
      return unless descendant

      # Add this descendant to deletion list
      descendants_array << descendant

      # Get all item IDs from this descendant
      all_item_ids = descendant.active_items + descendant.inactive_items

      # Fetch items with user_id filtering for safety
      items = Item.where(id: all_item_ids, user_id: user_id).includes(:descendant)

      items.each do |item|
        # Add item to deletion list
        items_array << item

        # Recursively collect from item's descendant if it exists
        if item.descendant
          collect_descendants_and_items(item.descendant, user_id, descendants_array, items_array)
        end
      end
    end

    # Start collection from day's descendant
    if day.descendant
      collect_descendants_and_items(day.descendant, user.id, descendants_to_delete, items_to_delete)
    end

    # Show summary
    puts "Found day for #{email} on #{date}"
    puts "  Day ID: #{day.id}"
    puts "  Day state: #{day.state}"
    puts "  Imported from: #{day.imported_from_day&.date || 'N/A'}"
    puts "  Imported to: #{day.imported_to_day&.date || 'N/A'}"
    puts ""
    puts "Will delete:"
    puts "  #{items_to_delete.count} items"
    puts "  #{descendants_to_delete.count} descendants"
    puts ""

    # Show first few items as sample
    if items_to_delete.any?
      puts "Sample items to delete (first 5):"
      items_to_delete.first(5).each do |item|
        puts "  - [#{item.id}] #{item.title} (#{item.item_type}, #{item.state})"
      end
      puts "  ... and #{items_to_delete.count - 5} more" if items_to_delete.count > 5
      puts ""
    end

    # Prompt for confirmation
    print "Are you sure you want to delete all items and descendants? (y/n): "
    confirmation = STDIN.gets.chomp.downcase

    unless confirmation == 'y'
      puts "Aborting."
      exit 0
    end

    # Get source day before deletion
    source_day = day.imported_from_day

    # Perform deletion in a transaction
    ActiveRecord::Base.transaction do
      # Delete all items
      items_to_delete.each(&:destroy!)
      puts "Deleted #{items_to_delete.count} items"

      # Delete all descendants
      descendants_to_delete.each(&:destroy!)
      puts "Deleted #{descendants_to_delete.count} descendants"

      # Null imported_from_day_id and imported_at from target day
      day.update!(
        imported_from_day_id: nil,
        imported_at: nil
      )
      puts "Cleared import relationship from target day"

      # Null imported_to_day_id from source day
      if source_day
        source_day.update!(imported_to_day_id: nil)
        puts "Cleared import relationship from source day"
      end

      puts ""
      puts "Successfully undid import for #{email} on #{date}"
    end
  end
end
