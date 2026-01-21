# frozen_string_literal: true

module Banking
  class ImportService
    Result = Struct.new(:success, :total, :imported, :skipped, :errors, keyword_init: true)

    def initialize(user, csv_content)
      @user = user
      @csv_content = csv_content
      @imported = 0
      @skipped = 0
      @errors = []
      @patterns = user.category_patterns.by_length_desc.includes(:category)
      @seen_hashes = Set.new
    end

    def call
      rows = parse_csv
      process_rows(rows)

      Result.new(
        success: @errors.empty?,
        total: rows.size,
        imported: @imported,
        skipped: @skipped,
        errors: @errors
      )
    rescue CSV::MalformedCSVError => e
      Result.new(
        success: false,
        total: 0,
        imported: 0,
        skipped: 0,
        errors: [ "Malformed CSV: #{e.message}" ]
      )
    rescue StandardError => e
      Result.new(
        success: false,
        total: 0,
        imported: 0,
        skipped: 0,
        errors: [ "Import failed: #{e.message}" ]
      )
    end

    private

    def parse_csv
      CSV.parse(@csv_content, headers: true, liberal_parsing: true)
    end

    def process_rows(rows)
      rows.each_with_index do |row, index|
        process_row(row, index + 2) # +2 for 1-indexed line number + header row
      end
    end

    def process_row(row, line_number)
      date = parse_date(row["Date"])
      description = row["Description"]&.strip
      value = parse_value(row["Value"])

      if date.nil? || description.blank? || value.nil?
        @errors << "Line #{line_number}: Missing or invalid required fields"
        return
      end

      row_hash = generate_row_hash(date, description, value)

      # Skip if already seen in this batch or exists in database
      if @seen_hashes.include?(row_hash) || @user.bank_transactions.exists?(row_hash: row_hash)
        @skipped += 1
        return
      end

      @seen_hashes.add(row_hash)
      matching_pattern = find_matching_pattern(description)

      transaction = @user.bank_transactions.create!(
        date: date,
        description: description,
        value: value,
        row_hash: row_hash,
        category_pattern: matching_pattern
      )

      # Create transaction_categorization if pattern matched a category
      if matching_pattern&.category
        TransactionCategorization.create!(
          bank_transaction: transaction,
          category: matching_pattern.category,
          user: @user,
          amount: nil
        )
      end

      @imported += 1
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      @skipped += 1
    end

    def parse_date(date_str)
      return nil if date_str.blank?

      # Handle DD-MM-YYYY format
      if date_str.match?(/\A\d{2}-\d{2}-\d{4}\z/)
        day, month, year = date_str.split("-").map(&:to_i)
        Date.new(year, month, day)
      else
        Date.parse(date_str)
      end
    rescue Date::Error, ArgumentError
      nil
    end

    def parse_value(value_str)
      return nil if value_str.blank?

      # Handle values with comma as decimal separator (e.g., "9,109.70" or "-24.28")
      # First, normalize the string by removing spaces
      normalized = value_str.to_s.strip

      # If there's both a comma and a period, determine which is the decimal separator
      # European format: 1.234,56 -> 1234.56
      # US format with thousands: 1,234.56 -> 1234.56
      if normalized.include?(",") && normalized.include?(".")
        # Check if comma comes after period (European: 1.234,56)
        if normalized.rindex(",") > normalized.rindex(".")
          # European format: period is thousands separator, comma is decimal
          normalized = normalized.delete(".").tr(",", ".")
        else
          # US format: comma is thousands separator, period is decimal
          normalized = normalized.delete(",")
        end
      elsif normalized.include?(",") && !normalized.include?(".")
        # Only comma present - could be decimal or thousands separator
        # If comma is followed by exactly 2 digits at end, it's likely decimal
        if normalized.match?(/,\d{2}\z/)
          normalized = normalized.tr(",", ".")
        else
          # Otherwise treat comma as thousands separator
          normalized = normalized.delete(",")
        end
      end

      BigDecimal(normalized)
    rescue ArgumentError
      nil
    end

    def generate_row_hash(date, description, value)
      # Normalize the value to consistent format for hashing
      normalized_value = value.to_s("F")
      data = "#{date.iso8601}|#{description.downcase}|#{normalized_value}"
      Digest::SHA256.hexdigest(data)
    end

    def find_matching_pattern(description)
      # Patterns are pre-ordered by length descending, so first match wins
      @patterns.find { |pattern| pattern.matches?(description) }
    end
  end
end
