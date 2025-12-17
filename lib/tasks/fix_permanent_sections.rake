# frozen_string_literal: true

namespace :days do
  desc "Add permanent sections to all existing days that don't have them"
  task add_permanent_sections: :environment do
    puts "Adding permanent sections to all existing days..."

    users_processed = 0
    days_processed = 0
    sections_created = 0

    User.find_each do |user|
      permanent_sections = user.permanent_sections || []

      if permanent_sections.empty?
        puts "User #{user.email} has no permanent sections defined - skipping"
        next
      end

      users_processed += 1
      puts "\nProcessing user: #{user.email}"
      puts "Permanent sections: #{permanent_sections.join(', ')}"

      user.days.each do |day|
        days_processed += 1

        # Ensure day has a descendant
        unless day.descendant
          day.create_descendant!(active_items: [], inactive_items: [])
          puts "  Created descendant for day #{day.date}"
        end

        permanent_sections.each do |section_name|
          # Check if section already exists on day
          section_ids = day.descendant.extract_active_item_ids
          existing_sections = Item.sections.where(id: section_ids, title: section_name)

          if existing_sections.any?
            puts "  Day #{day.date}: Section '#{section_name}' already exists - skipping"
            next
          end

          # Create section item
          section = user.items.create!(
            title: section_name,
            item_type: :section,
            state: :todo,
            extra_data: { permanent_section: true }
          )

          # Ensure section has a descendant
          unless section.descendant
            section.create_descendant!(active_items: [], inactive_items: [])
          end

          # Add section to day's active items
          day.descendant.add_active_item(section.id)
          day.descendant.save!

          sections_created += 1
          puts "  Day #{day.date}: Created section '#{section_name}'"
        end
      end
    end

    puts "\n" + "="*80
    puts "SUMMARY:"
    puts "  Users processed: #{users_processed}"
    puts "  Days processed: #{days_processed}"
    puts "  Sections created: #{sections_created}"
    puts "="*80
  end
end
