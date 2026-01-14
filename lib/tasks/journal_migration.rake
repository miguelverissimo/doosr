# frozen_string_literal: true

namespace :journal do
  desc "Migrate journals from old password-based encryption to new seed-based encryption"
  task migrate_to_seed_encryption: :environment do
    puts "Journal Encryption Migration Tool"
    puts "=" * 50
    puts "\nThis tool will migrate your journals from the old encryption system to the new one."
    puts "You'll need:"
    puts "  1. Your OLD password (before recovery)"
    puts "  2. Your seed phrase"
    puts "  3. Your NEW password (after recovery)"
    puts ""

    print "Enter your email: "
    email = STDIN.gets.chomp

    user = User.find_by(email: email)
    unless user
      puts "ERROR: User not found"
      exit 1
    end

    unless user.journal_protection_enabled?
      puts "ERROR: Journal protection is not enabled for this user"
      exit 1
    end

    print "Enter your OLD password (before recovery): "
    old_password = STDIN.noecho(&:gets).chomp
    puts ""

    # Verify old password can decrypt journals
    salt = user.journal_encryption_salt
    old_key = Journals::EncryptionService.derive_key(old_password, salt)

    # Test decryption on first encrypted fragment
    test_fragment = user.journal_fragments.where.not(encrypted_content: nil).first
    unless test_fragment
      puts "No encrypted fragments found. Nothing to migrate."
      exit 0
    end

    begin
      test_fragment.decrypted_content(old_key)
      puts "✓ Old password verified"
    rescue Journals::EncryptionService::DecryptionError
      puts "ERROR: Old password is incorrect or fragments are encrypted with a different key"
      exit 1
    end

    print "Enter your seed phrase (12 words): "
    seed_phrase = STDIN.gets.chomp.strip.downcase.split(/\s+/).join(" ")
    puts ""

    unless Journals::MnemonicService.validate(seed_phrase)
      puts "ERROR: Invalid seed phrase format"
      exit 1
    end

    print "Enter your NEW password (after recovery): "
    new_password = STDIN.noecho(&:gets).chomp
    puts ""

    # Derive new keys
    new_password_key = Journals::EncryptionService.derive_key(new_password, salt)
    new_encryption_key = Journals::EncryptionService.derive_key(seed_phrase, salt)

    # Verify new password matches stored digest
    unless BCrypt::Password.new(user.journal_password_digest) == new_password
      puts "ERROR: New password is incorrect"
      exit 1
    end

    puts "\nStarting migration..."
    puts "This will re-encrypt all your journal fragments with the seed-derived key."
    print "Continue? (yes/no): "
    confirm = STDIN.gets.chomp

    unless confirm.downcase == "yes"
      puts "Migration cancelled"
      exit 0
    end

    # Migrate all fragments
    total = user.journal_fragments.where.not(encrypted_content: nil).count
    migrated = 0
    errors = 0

    user.journal_fragments.where.not(encrypted_content: nil).find_each do |fragment|
      begin
        # Decrypt with old key
        plaintext = fragment.decrypted_content(old_key)

        # Re-encrypt with new key
        result = Journals::EncryptionService.encrypt(plaintext, new_encryption_key)

        # Update fragment
        fragment.update!(
          encrypted_content: result[:ciphertext],
          encryption_iv: result[:iv],
          encryption_auth_tag: result[:auth_tag]
        )

        migrated += 1
        print "\rMigrated #{migrated}/#{total} fragments..."
      rescue => e
        errors += 1
        puts "\nERROR migrating fragment #{fragment.id}: #{e.message}"
      end
    end

    puts "\n\nMigration complete!"
    puts "Successfully migrated: #{migrated}"
    puts "Errors: #{errors}"

    # Update encrypted seed phrase with new password
    encrypted_seed = Journals::EncryptionService.encrypt(seed_phrase, new_password_key)
    user.update!(
      encrypted_seed_phrase: [ encrypted_seed[:ciphertext], encrypted_seed[:iv], encrypted_seed[:auth_tag] ].join(":")
    )

    puts "✓ Seed phrase updated"
    puts "\nYou can now unlock your journals with your new password!"
  end
end
