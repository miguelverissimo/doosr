# frozen_string_literal: true

module Banking
  class PaymentReminderProcessorService
    SECTION_TITLE = "Financial Operations"

    Result = Struct.new(:success, :items_created, :skipped_count, :errors, keyword_init: true)

    def initialize(user, date: Date.current)
      @user = user
      @date = date
      @items_created = 0
      @skipped_count = 0
      @errors = []
    end

    def call
      process_reminders
      Result.new(
        success: @errors.empty?,
        items_created: @items_created,
        skipped_count: @skipped_count,
        errors: @errors
      )
    rescue StandardError => e
      Result.new(
        success: false,
        items_created: @items_created,
        skipped_count: @skipped_count,
        errors: ["Processing failed: #{e.message}"]
      )
    end

    private

    def process_reminders
      reminders_due_today.each do |reminder|
        process_reminder(reminder)
      end
    end

    def reminders_due_today
      reminders = @user.payment_reminders.active.select do |reminder|
        should_remind = reminder.should_remind_on?(@date)
        Rails.logger.debug "PaymentReminderProcessorService: Reminder #{reminder.id} " \
                          "(cutoff: #{reminder.cutoff_date}, days_before: #{reminder.reminder_days_before.inspect}) " \
                          "should_remind_on?(#{@date}): #{should_remind}"
        should_remind
      end
      Rails.logger.info "PaymentReminderProcessorService: Found #{reminders.count} reminders due on #{@date}"
      reminders
    end

    def process_reminder(reminder)
      if reminder.reminder_item_exists_for_date?(@date)
        Rails.logger.debug "PaymentReminderProcessorService: Reminder #{reminder.id} - item already exists for #{@date}"
        return skip_existing(reminder)
      end

      Rails.logger.info "PaymentReminderProcessorService: Processing reminder #{reminder.id} (#{reminder.title}) for #{@date}"

      day = find_or_create_day
      unless day
        Rails.logger.error "PaymentReminderProcessorService: Could not find or create day for #{@date}"
        return skip_no_day(reminder)
      end

      section = find_or_create_section(day)
      unless section
        Rails.logger.error "PaymentReminderProcessorService: Could not find or create section for day #{day.id}"
        return skip_no_section(reminder)
      end

      create_reminder_item(reminder, section)
      Rails.logger.info "PaymentReminderProcessorService: Created item for reminder #{reminder.id}"
    end

    def find_or_create_day
      @user.days.find_or_create_by!(date: @date) do |day|
        day.state = :open
      end.tap do |day|
        day.descendant || day.create_descendant!(active_items: [], inactive_items: [])
      end
    end

    def find_or_create_section(day)
      existing_section = find_existing_section(day)
      return existing_section if existing_section

      create_section(day)
    end

    def find_existing_section(day)
      return nil unless day.descendant

      section_ids = day.descendant.extract_active_item_ids
      Item.sections
          .where(id: section_ids)
          .where("LOWER(title) = ?", SECTION_TITLE.downcase)
          .first
    end

    def create_section(day)
      section = @user.items.create!(
        title: SECTION_TITLE,
        item_type: :section,
        state: :todo,
        extra_data: { financial_operations_section: true }
      )

      section.descendant || section.create_descendant!(active_items: [], inactive_items: [])

      # Prepend to make it the topmost section
      day.descendant.active_items.unshift({ "Item" => section.id })
      day.descendant.save!

      section
    end

    def create_reminder_item(reminder, section)
      days_until = reminder.days_until_cutoff(@date)

      item = @user.items.create!(
        title: build_item_title(reminder, days_until),
        item_type: :completable,
        state: :todo,
        extra_data: build_extra_data(reminder, days_until)
      )

      section.descendant.add_active_item(item.id)
      section.descendant.save!

      @items_created += 1
    end

    def build_item_title(reminder, days_until)
      if days_until == 0
        "#{reminder.title} (DUE TODAY)"
      elsif days_until == 1
        "#{reminder.title} (due tomorrow)"
      else
        "#{reminder.title} (due in #{days_until} days)"
      end
    end

    def build_extra_data(reminder, days_until)
      {
        payment_reminder_id: reminder.id,
        payment_reminder_title: reminder.title,
        payment_url: reminder.payment_url,
        cutoff_date: reminder.cutoff_date.to_s,
        days_until_cutoff: days_until,
        reminder_date: @date.to_s
      }
    end

    def skip_existing(reminder)
      @skipped_count += 1
      Rails.logger.debug "Skipped reminder #{reminder.id} - item already exists for #{@date}"
    end

    def skip_no_day(reminder)
      @errors << "Could not find or create day for reminder #{reminder.id}"
    end

    def skip_no_section(reminder)
      @errors << "Could not find or create section for reminder #{reminder.id}"
    end
  end
end
