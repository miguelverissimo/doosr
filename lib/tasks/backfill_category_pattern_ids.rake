# frozen_string_literal: true

namespace :banking do
  desc "Backfill category_pattern_id for existing transactions that match patterns"
  task backfill_category_pattern_ids: :environment do
    puts "Starting backfill of category_pattern_id..."

    total_updated = 0
    total_users = User.count

    User.find_each.with_index do |user, index|
      patterns = user.category_patterns.by_length_desc.to_a
      next if patterns.empty?

      # Find transactions with a category but no pattern association
      transactions = user.bank_transactions
        .where.not(category_id: nil)
        .where(category_pattern_id: nil)

      user_updated = 0

      transactions.find_each do |transaction|
        # Find the first pattern that matches this transaction's description
        # AND has the same category as the transaction
        matching_pattern = patterns.find do |pattern|
          pattern.matches?(transaction.description) && pattern.category_id == transaction.category_id
        end

        if matching_pattern
          transaction.update_column(:category_pattern_id, matching_pattern.id)
          user_updated += 1
        end
      end

      total_updated += user_updated
      puts "User #{index + 1}/#{total_users}: Updated #{user_updated} transactions"
    end

    puts "Backfill complete. Total transactions updated: #{total_updated}"
  end
end
