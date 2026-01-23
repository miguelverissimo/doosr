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

    # Process a single reminder immediately (called on create/update)
    # This ensures notifications are scheduled right away without waiting for the job
    def process_single(reminder)
      return unless reminder.active? && reminder.should_remind_on?(@date)

      process_reminder(reminder)
      Result.new(
        success: @errors.empty?,
        items_created: @items_created,
        skipped_count: @skipped_count,
        errors: @errors
      )
    rescue StandardError => e
      Rails.logger.error "PaymentReminderProcessorService: Failed to process single reminder #{reminder.id}: #{e.message}"
      Result.new(success: false, items_created: 0, skipped_count: 0, errors: [e.message])
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
      existing_day_reminder = @user.day_payment_reminders.find_by(payment_reminder: reminder, reminder_date: @date)

      if existing_day_reminder
        Rails.logger.debug "PaymentReminderProcessorService: Reminder #{reminder.id} - item already exists for #{@date}"
        # Still try to schedule notification if not already done
        schedule_notification_if_needed(reminder, existing_day_reminder)
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

      day_payment_reminder = @user.day_payment_reminders.create!(
        payment_reminder: reminder,
        reminder_date: @date,
        days_until_cutoff: days_until
      )

      section.descendant.add_active_record("DayPaymentReminder", day_payment_reminder.id)
      section.descendant.save!

      # Schedule push notification if notification_time is set
      schedule_notification(reminder, day_payment_reminder) if reminder.notification_time.present?

      @items_created += 1
    end

    def schedule_notification_if_needed(reminder, day_payment_reminder)
      return unless reminder.notification_time.present?
      return if day_payment_reminder.paid?
      return if notification_already_scheduled?(day_payment_reminder)

      schedule_notification(reminder, day_payment_reminder)
    end

    def notification_already_scheduled?(day_payment_reminder)
      # Check if there's a pending job for this day_payment_reminder
      SolidQueue::Job
        .where(class_name: "PaymentReminderNotificationJob")
        .where(finished_at: nil)
        .where("arguments LIKE ?", "%day_payment_reminder_id\":#{day_payment_reminder.id}%")
        .exists?
    end

    NOTIFICATION_GRACE_PERIOD = 1.hour

    def schedule_notification(reminder, day_payment_reminder)
      # Build notification time for today at the specified time
      notification_datetime = @date.in_time_zone.change(
        hour: reminder.notification_time.hour,
        min: reminder.notification_time.min
      )

      # Schedule if in the future OR within the grace period (1 hour ago)
      # This handles cases where the job runs slightly after the notification time
      return if notification_datetime < Time.current - NOTIFICATION_GRACE_PERIOD

      title = "Payment Reminder: #{reminder.title}"
      body = if day_payment_reminder.days_until_cutoff.zero?
        "Payment due today!"
      elsif day_payment_reminder.days_until_cutoff == 1
        "Payment due tomorrow"
      else
        "Payment due in #{day_payment_reminder.days_until_cutoff} days"
      end

      if reminder.expected_amount.present?
        body += " (#{sprintf('%.2f', reminder.expected_amount)})"
      end

      job_args = {
        user_id: @user.id,
        payment_reminder_id: reminder.id,
        day_payment_reminder_id: day_payment_reminder.id,
        title: title,
        body: body
      }

      # If notification time is in the past (but within grace period), send immediately
      # Otherwise schedule for the specified time
      if notification_datetime <= Time.current
        PaymentReminderNotificationJob.perform_later(**job_args)
        Rails.logger.info "PaymentReminderProcessorService: Sending immediate notification for reminder #{reminder.id} (was scheduled for #{notification_datetime})"
      else
        PaymentReminderNotificationJob.set(wait_until: notification_datetime).perform_later(**job_args)
        Rails.logger.info "PaymentReminderProcessorService: Scheduled notification for reminder #{reminder.id} at #{notification_datetime}"
      end
    rescue StandardError => e
      Rails.logger.error "Failed to schedule notification for payment reminder #{reminder.id}: #{e.message}"
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
