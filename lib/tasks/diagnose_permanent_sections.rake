# frozen_string_literal: true

namespace :diagnose do
  desc "Diagnose permanent section issues in production"
  task permanent_sections: :environment do
    puts "\n=== PERMANENT SECTION DIAGNOSIS ==="
    puts "This script checks for sections that should be permanent but are missing the flag\n\n"

    User.find_each do |user|
      next if user.permanent_sections.blank?

      puts "User: #{user.email}"
      puts "Configured permanent sections: #{user.permanent_sections.inspect}"

      # Find all days for this user
      user.days.where.not(descendant: nil).each do |day|
        day_sections = []

        # Get all sections at the root of the day
        active_ids = day.descendant.extract_active_item_ids
        sections = Item.where(id: active_ids, item_type: :section)

        sections.each do |section|
          # Check if this section title matches a permanent section
          is_configured_permanent = user.permanent_sections.any? { |ps| ps.downcase == section.title.downcase }
          has_flag = section.extra_data&.dig("permanent_section") == true

          if is_configured_permanent
            status = if has_flag
              "✓ OK"
            else
              "✗ MISSING FLAG"
            end

            day_sections << {
              id: section.id,
              title: section.title,
              has_flag: has_flag,
              status: status
            }
          end
        end

        if day_sections.any?
          puts "  Day #{day.date}:"
          day_sections.each do |sec|
            puts "    #{sec[:status]} - Section #{sec[:id]}: #{sec[:title]} (has_flag: #{sec[:has_flag]})"
          end
        end
      end

      puts "\n"
    end

    puts "\n=== FIXING MISSING FLAGS ==="
    puts "Run this command to fix sections missing the permanent_section flag:"
    puts "  bin/rails fix:permanent_section_flags"
  end

  desc "Check specific day for duplicate permanent sections"
  task :check_day, [ :date ] => :environment do |t, args|
    date = Date.parse(args[:date])

    User.find_each do |user|
      day = user.days.find_by(date: date)
      next unless day

      puts "\n=== Day #{date} for #{user.email} ==="

      active_ids = day.descendant.extract_active_item_ids
      items = Item.where(id: active_ids)

      puts "Total items at root: #{items.count}"

      sections = items.where(item_type: :section)
      puts "Total sections at root: #{sections.count}"

      permanent_sections = sections.where("extra_data ->> 'permanent_section' = 'true'")
      puts "Permanent sections (with flag): #{permanent_sections.count}"

      sections.each do |section|
        has_flag = section.extra_data&.dig("permanent_section") == true
        child_count = section.descendant&.extract_active_item_ids&.length || 0

        puts "  Section #{section.id}: #{section.title}"
        puts "    - Has permanent flag: #{has_flag}"
        puts "    - Children: #{child_count}"
        puts "    - Source item: #{section.source_item_id || 'none'}"
      end

      # Check for duplicates
      section_titles = sections.pluck(:title)
      duplicates = section_titles.group_by(&:itself).select { |k, v| v.count > 1 }

      if duplicates.any?
        puts "\n⚠️  DUPLICATES DETECTED:"
        duplicates.each do |title, occurrences|
          puts "  '#{title}' appears #{occurrences.count} times"
        end
      else
        puts "\n✓ No duplicate sections found"
      end
    end
  end
end

namespace :fix do
  desc "Add permanent_section flag to sections that should have it"
  task permanent_section_flags: :environment do
    puts "\n=== FIXING PERMANENT SECTION FLAGS ==="

    fixed_count = 0

    ActiveRecord::Base.transaction do
      User.find_each do |user|
        next if user.permanent_sections.blank?

        puts "User: #{user.email}"
        puts "Configured permanent sections: #{user.permanent_sections.inspect}"

        # Find all days for this user
        user.days.where.not(descendant: nil).each do |day|
          active_ids = day.descendant.extract_active_item_ids
          sections = Item.where(id: active_ids, item_type: :section)

          sections.each do |section|
            # Check if this section title matches a permanent section (case-insensitive)
            is_configured_permanent = user.permanent_sections.any? { |ps| ps.downcase == section.title.downcase }
            has_flag = section.extra_data&.dig("permanent_section") == true

            if is_configured_permanent && !has_flag
              puts "  Fixing section #{section.id} '#{section.title}' on day #{day.date}"

              extra_data = section.extra_data || {}
              extra_data["permanent_section"] = true
              section.update!(extra_data: extra_data)

              fixed_count += 1
            end
          end
        end
      end
    end

    puts "\n✓ Fixed #{fixed_count} sections"
  end
end
