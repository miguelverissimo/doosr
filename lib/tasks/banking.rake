# frozen_string_literal: true

namespace :banking do
  desc "Assign unassigned bank transactions to a specific account"
  task :assign_transactions, [ :email, :account_name ] => :environment do |_task, args|
    email = args[:email]
    account_name = args[:account_name]

    if email.blank? || account_name.blank?
      puts "Usage: bin/rails banking:assign_transactions[email,account_name]"
      puts "Example: bin/rails banking:assign_transactions[user@example.com,Main Checking]"
      exit 1
    end

    user = User.find_by(email: email)
    unless user
      puts "Error: User with email '#{email}' not found."
      exit 1
    end

    puts "Found user: #{user.email} (ID: #{user.id})"

    account = user.bank_accounts.find_by(name: account_name)

    unless account
      puts "\nBank account '#{account_name}' not found for this user."
      puts "Available accounts:"

      if user.bank_accounts.any?
        user.bank_accounts.order(:name).each do |a|
          puts "  - #{a.name} (#{a.account_type})"
        end
      else
        puts "  (no accounts)"
      end

      print "\nWould you like to create the account '#{account_name}'? [y/N] "
      response = $stdin.gets&.strip&.downcase

      if response == "y" || response == "yes"
        print "Account type (checking/savings/credit_card/investment/other) [checking]: "
        account_type = $stdin.gets&.strip.presence || "checking"

        unless BankAccount::ACCOUNT_TYPES.include?(account_type)
          puts "Error: Invalid account type '#{account_type}'. Must be one of: #{BankAccount::ACCOUNT_TYPES.join(', ')}"
          exit 1
        end

        account = user.bank_accounts.create!(name: account_name, account_type: account_type)
        puts "Created account '#{account.name}' (#{account.account_type})"
      else
        puts "Aborted."
        exit 0
      end
    end

    unassigned_count = user.bank_transactions.where(bank_account_id: nil).count

    if unassigned_count.zero?
      puts "\nNo unassigned transactions found for this user."
      exit 0
    end

    puts "\nFound #{unassigned_count} unassigned transaction(s)."
    print "Assign all to '#{account.name}'? [y/N] "
    response = $stdin.gets&.strip&.downcase

    if response == "y" || response == "yes"
      updated = user.bank_transactions.where(bank_account_id: nil).update_all(bank_account_id: account.id)
      puts "Successfully assigned #{updated} transaction(s) to '#{account.name}'."
    else
      puts "Aborted."
    end
  end
end
