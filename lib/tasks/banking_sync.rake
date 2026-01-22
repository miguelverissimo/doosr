namespace :banking do
  desc "Export categories and patterns from a user to a JSON file"
  task export_categories: :environment do
    email = ENV.fetch("USER_EMAIL") { raise "USER_EMAIL is required" }
    output_file = ENV.fetch("OUTPUT_FILE", "tmp/banking_categories_export.json")

    user = User.find_by!(email: email)

    categories = user.categories.includes(:category_patterns).map do |category|
      {
        name: category.name,
        color: category.color,
        patterns: category.category_patterns.map(&:pattern)
      }
    end

    data = {
      exported_at: Time.current.iso8601,
      source_user_email: email,
      categories: categories
    }

    File.write(output_file, JSON.pretty_generate(data))

    puts "Exported #{categories.count} categories with #{categories.sum { |c| c[:patterns].count }} patterns"
    puts "Output: #{output_file}"
  end

  desc "Import categories and patterns to a user (replaces existing)"
  task import_categories: :environment do
    email = ENV.fetch("USER_EMAIL") { raise "USER_EMAIL is required" }

    user = User.find_by!(email: email)

    categories_data = [
      { name: "Groceries", color: "#ca8a04", patterns: [ "MERCADONA", "ALDI", "AUCHAN", "PINGO DOCE", "Lidl", "CONTINENTE" ] },
      { name: "Subscriptions", color: "#dc2626", patterns: [ "APPLE.COM/BILL ITUNES.COM", "PAYPAL TRENDS RESE", "T3 CHAT", "PAYPAL PATREONIREL", "DECO PROTESTE", "HUMBLEBUNDL", "PATREON", "BLINKIST", "Audible", "BOLT BY STACKBLITZ", "MEDIUM.COM" ] },
      { name: "Health", color: "#14b8a6", patterns: [ "MEDICAL PLUS", "FARMACIA", "WELL'S", "Generali" ] },
      { name: "AI Tools", color: "#06b6d4", patterns: [ "OPENAI", "CURSOR, AI POWERED" ] },
      { name: "Bank Fees", color: "#a855f7", patterns: [ "COMISSAO", "COMISSÃO", "IMPOSTO DE SELO", "MANUTENCAO DE CONTA" ] },
      { name: "Amazon", color: "#eab308", patterns: [ "AMZN", "WWW.AMAZON", "Kindle", "AMAZON" ] },
      { name: "Work", color: "#ea580c", patterns: [ "PAYPAL GOOGLE", "OPENSOURCEC", "PROTONMAIL", "Ludmila Maria Balsinha Rebola", "Hetzner", "MICROSOFT", "NAMECHEAP", "LUDMILA", "APPLE.COM" ] },
      { name: "Sara", color: "#06b6d4", patterns: [ "A COUTENSE", "CASA DO SOL" ] },
      { name: "Car", color: "#eab308", patterns: [ "BARREIRINHO", "PORTAGEM", "A.S. VOUZELA", "A.S. VISEU", "MAINSTATION", "REPSOL" ] },
      { name: "Home", color: "#78716c", patterns: [ "AGRILOJA", "CASH BRICO", "SERV MUN VISEU", "IKEA", "PAVILECTRICA", "MEO, SA", "GOLD ENERGY", "CAMPOCHEIO", "LEROY MERLIN", "SUBSCRICAO PLANO DE REFORMA" ] },
      { name: "Taxes", color: "#db2777", patterns: [ "SEG SOCIAL", "INSTITUTO DE GESTAO FINANCEIRA" ] },
      { name: "Insurance", color: "#db2777", patterns: [ "FIDELIDADE" ] },
      { name: "Studies", color: "#65a30d", patterns: [] },
      { name: "Misc", color: "#475569", patterns: [] },
      { name: "Salary", color: "#16a34a", patterns: [ "PRECISION HEALTH INC" ] },
      { name: "Debt", color: "#db2777", patterns: [ "PT50003501970000819050039" ] }
    ]

    total_patterns = categories_data.sum { |c| c[:patterns].count }

    puts "Target user: #{email}"
    puts "Categories to import: #{categories_data.count}"
    puts "Total patterns: #{total_patterns}"
    puts ""

    existing_categories = user.categories.count
    existing_patterns = user.category_patterns.count

    puts "Current user has: #{existing_categories} categories, #{existing_patterns} patterns"
    puts ""
    puts "This will DELETE all existing categories and patterns for this user."
    print "Continue? (yes/no): "

    confirmation = $stdin.gets&.chomp
    unless confirmation == "yes"
      puts "Aborted."
      exit 1
    end

    ActiveRecord::Base.transaction do
      # Nullify category references in transactions first
      user.bank_transactions.update_all(category_id: nil)

      # Delete existing patterns and categories
      user.category_patterns.delete_all
      user.categories.delete_all

      # Import new categories and patterns
      categories_data.each do |cat_data|
        category = user.categories.create!(
          name: cat_data[:name],
          color: cat_data[:color]
        )

        cat_data[:patterns].each do |pattern|
          user.category_patterns.create!(
            pattern: pattern,
            category: category
          )
        end
      end
    end

    puts ""
    puts "Import complete!"
    puts "Created: #{user.categories.count} categories, #{user.category_patterns.count} patterns"
  end

  desc "Manually trigger payment reminder check for a user or all users"
  task check_payment_reminders: :environment do
    email = ENV["USER_EMAIL"]
    date = ENV["DATE"] ? Date.parse(ENV["DATE"]) : Date.current

    if email
      user = User.find_by!(email: email)
      puts "Checking payment reminders for user: #{email} (date: #{date})"
      result = Banking::PaymentReminderProcessorService.new(user, date: date).call
      puts "Result: Created #{result.items_created} items, Skipped #{result.skipped_count}, Errors: #{result.errors.join(', ')}"
    else
      puts "Checking payment reminders for all users (date: #{date})"
      Banking::PaymentReminderCheckJob.new.perform
      puts "Check complete. See logs for details."
    end
  end
end
