namespace :ephemeries do
  desc "Import ephemeries from a JSON file"
  task :import, [:file_path] => :environment do |_t, args|
    file_path = args[:file_path] || Rails.root.join("data", "ephemeries.json")

    unless File.exist?(file_path)
      puts "Error: File not found at #{file_path}"
      puts "Usage: bin/rails ephemeries:import[/path/to/ephemeries.json]"
      exit 1
    end

    puts "Reading ephemeries from #{file_path}..."
    json_data = JSON.parse(File.read(file_path))

    puts "Found #{json_data.length} ephemeries to import"

    imported_count = 0
    skipped_count = 0
    error_count = 0

    ActiveRecord::Base.transaction do
      json_data.each_with_index do |entry, index|
        begin
          # Parse dates - the JSON format is "24 November 2025"
          start_date = parse_date_string(entry["start"])
          end_date = parse_date_string(entry["end"])
          strongest_date = entry["strongest"].present? ? parse_date_string(entry["strongest"]) : nil

          # Convert to UTC datetime at midnight
          start_datetime = start_date.to_time.utc.beginning_of_day
          end_datetime = end_date.to_time.utc.beginning_of_day
          strongest_datetime = strongest_date ? strongest_date.to_time.utc.beginning_of_day : nil

          # Check if this ephemery already exists (by start, end, and aspect)
          existing = Ephemery.find_by(
            start: start_datetime,
            end: end_datetime,
            aspect: entry["aspect"]
          )

          if existing
            puts "  [#{index + 1}] Skipped (already exists): #{entry['aspect']}"
            skipped_count += 1
            next
          end

          ephemery = Ephemery.create!(
            start: start_datetime,
            end: end_datetime,
            strongest: strongest_datetime,
            aspect: entry["aspect"],
            description: entry["description"]
          )

          puts "  [#{index + 1}] Imported: #{ephemery.aspect} (#{start_date} to #{end_date})"
          imported_count += 1
        rescue StandardError => e
          puts "  [#{index + 1}] Error: #{e.message}"
          puts "    Entry: #{entry.inspect}"
          error_count += 1
        end
      end
    end

    puts "\n" + "=" * 60
    puts "Import completed!"
    puts "  Imported: #{imported_count}"
    puts "  Skipped:  #{skipped_count}"
    puts "  Errors:   #{error_count}"
    puts "  Total:    #{json_data.length}"
    puts "=" * 60
  end

  desc "Clear all ephemeries from the database"
  task clear: :environment do
    count = Ephemery.count
    print "Are you sure you want to delete all #{count} ephemeries? (yes/no): "
    confirmation = $stdin.gets.chomp

    if confirmation.downcase == "yes"
      Ephemery.delete_all
      puts "Deleted all ephemeries."
    else
      puts "Cancelled."
    end
  end

  def parse_date_string(date_str)
    # Parse format like "24 November 2025"
    Date.parse(date_str)
  rescue ArgumentError => e
    raise "Failed to parse date '#{date_str}': #{e.message}"
  end
end
