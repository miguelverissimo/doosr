# frozen_string_literal: true

namespace :journal do
  desc "Force reset journal protection (accepts data loss)"
  task force_reset_protection: :environment do
    puts "Journal Protection Force Reset"
    puts "=" * 50
    puts "\n⚠️  WARNING: This will:"
    puts "  - Disable journal protection"
    puts "  - Delete all encrypted journal content (PERMANENT DATA LOSS)"
    puts "  - Clear your seed phrase and encryption settings"
    puts ""

    print "Enter your email: "
    email = STDIN.gets.chomp

    user = User.find_by(email: email)
    unless user
      puts "ERROR: User not found"
      exit 1
    end

    unless user.journal_protection_enabled?
      puts "Journal protection is already disabled for this user"
      exit 0
    end

    encrypted_count = user.journal_fragments.where.not(encrypted_content: nil).count
    puts "\nFound #{encrypted_count} encrypted journal fragments that will be DELETED."
    puts ""
    print "Type 'DELETE ALL' to confirm: "
    confirm = STDIN.gets.chomp

    unless confirm == "DELETE ALL"
      puts "Reset cancelled"
      exit 0
    end

    puts "\nResetting journal protection..."

    # Delete all encrypted fragments
    deleted = user.journal_fragments.where.not(encrypted_content: nil).delete_all
    puts "✓ Deleted #{deleted} encrypted fragments"

    # Clear protection settings
    user.update!(
      journal_password_digest: nil,
      encrypted_seed_phrase: nil,
      journal_encryption_salt: nil,
      journal_protection_enabled: false
    )
    puts "✓ Cleared protection settings"

    # Clear any cached sessions
    Rails.cache.delete_matched("journal_session:#{user.id}:*")
    puts "✓ Cleared cached sessions"

    puts "\n✅ Journal protection has been reset!"
    puts "You can now enable protection again with a new password and seed phrase."
  end
end
