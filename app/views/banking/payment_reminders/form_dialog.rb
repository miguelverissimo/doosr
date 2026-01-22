# frozen_string_literal: true

module Views
  module Banking
    module PaymentReminders
      class FormDialog < ::Views::Base
        REMINDER_DAY_OPTIONS_LEFT = [
          { value: 30, label: "1 month before" },
          { value: 21, label: "3 weeks before" },
          { value: 14, label: "2 weeks before" },
          { value: 7, label: "1 week before" }
        ].freeze

        REMINDER_DAY_OPTIONS_RIGHT = [
          { value: 5, label: "5 days before" },
          { value: 3, label: "3 days before" },
          { value: 2, label: "2 days before" },
          { value: 1, label: "1 day before" },
          { value: 0, label: "On due date" }
        ].freeze

        DEFAULT_REMINDER_DAYS = [7, 3, 0].freeze

        def initialize(payment_reminder:)
          @payment_reminder = payment_reminder
        end

        def view_template
          div(id: "payment_reminder_form_dialog") do
            render RubyUI::Dialog.new(open: true) do
              render RubyUI::DialogContent.new(size: :lg) do
                render RubyUI::DialogHeader.new do
                  render RubyUI::DialogTitle.new { dialog_title }
                  render RubyUI::DialogDescription.new { dialog_description }
                end

                render RubyUI::DialogMiddle.new do
                  render_form
                end
              end
            end
          end
        end

        private

        def editing?
          @payment_reminder.persisted?
        end

        def dialog_title
          editing? ? "Edit Payment Reminder" : "Add Payment Reminder"
        end

        def dialog_description
          editing? ? "Update your payment reminder details" : "Create a recurring reminder for an upcoming payment"
        end

        def form_action
          if editing?
            view_context.banking_payment_reminder_path(@payment_reminder)
          else
            view_context.banking_payment_reminders_path
          end
        end

        def loading_message
          editing? ? "Updating reminder..." : "Creating reminder..."
        end

        def success_message
          editing? ? "Reminder updated successfully" : "Reminder created successfully"
        end

        def submit_button_text
          editing? ? "Update Reminder" : "Add Reminder"
        end

        def render_form
          form(
            action: form_action,
            method: "post",
            data: {
              controller: "modal-form",
              modal_form_loading_message_value: loading_message,
              modal_form_success_message_value: success_message,
              turbo: true
            },
            class: "space-y-4"
          ) do
            csrf_token_field
            render RubyUI::Input.new(type: :hidden, name: "_method", value: "patch") if editing?

            div(id: "payment_reminder_form_errors", class: "text-sm text-destructive")

            render_title_field
            render_expected_amount_field
            render_cutoff_date_field
            render_payment_url_field
            render_reminder_days_field
            render_notification_time_field
            render_active_field

            render_actions
          end
        end

        def csrf_token_field
          render RubyUI::Input.new(
            type: :hidden,
            name: "authenticity_token",
            value: view_context.form_authenticity_token
          )
        end

        def render_title_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "payment_reminder_title") { "Payment Title" }
            render RubyUI::Input.new(
              type: :text,
              id: "payment_reminder_title",
              name: "payment_reminder[title]",
              value: @payment_reminder.title,
              required: true,
              placeholder: "e.g., Property Tax, Insurance Premium"
            )
            render RubyUI::FormFieldError.new
          end
        end

        def render_expected_amount_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "payment_reminder_expected_amount") { "Expected Amount" }
            render RubyUI::Input.new(
              type: :number,
              id: "payment_reminder_expected_amount",
              name: "payment_reminder[expected_amount]",
              value: @payment_reminder.expected_amount.present? ? format_number_for_input(@payment_reminder.expected_amount) : nil,
              required: true,
              step: "0.01",
              min: "0",
              placeholder: "0.00"
            )
            render RubyUI::FormFieldError.new
          end
        end

        def render_cutoff_date_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "payment_reminder_cutoff_date") { "Payment Due Date" }
            render RubyUI::Input.new(
              type: :date,
              id: "payment_reminder_cutoff_date",
              name: "payment_reminder[cutoff_date]",
              value: @payment_reminder.cutoff_date&.to_s,
              required: true,
              class: "date-input-icon-light-dark"
            )
            render RubyUI::FormFieldError.new
          end
        end

        def render_payment_url_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "payment_reminder_payment_url") { "Payment URL (Optional)" }
            render RubyUI::Input.new(
              type: :url,
              id: "payment_reminder_payment_url",
              name: "payment_reminder[payment_url]",
              value: @payment_reminder.payment_url,
              placeholder: "https://example.com/pay"
            )
            p(class: "text-xs text-muted-foreground mt-1") { "Link to the payment page for quick access" }
            render RubyUI::FormFieldError.new
          end
        end

        def render_reminder_days_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new { "Remind Me" }
            div(class: "grid grid-cols-2 gap-x-6 gap-y-2 mt-2") do
              div(class: "space-y-2") do
                REMINDER_DAY_OPTIONS_LEFT.each do |option|
                  render_checkbox_option(option)
                end
              end
              div(class: "space-y-2") do
                REMINDER_DAY_OPTIONS_RIGHT.each do |option|
                  render_checkbox_option(option)
                end
              end
            end
            p(class: "text-xs text-muted-foreground mt-2") { "Select when you want to be reminded" }
            render RubyUI::FormFieldError.new
          end
        end

        def render_checkbox_option(option)
          checked = if @payment_reminder.persisted?
            @payment_reminder.reminder_days_before&.include?(option[:value])
          else
            DEFAULT_REMINDER_DAYS.include?(option[:value])
          end

          label(class: "flex items-center gap-2 cursor-pointer") do
            input(
              type: "checkbox",
              name: "payment_reminder[reminder_days_before][]",
              value: option[:value],
              checked: checked,
              class: "h-4 w-4 rounded border-gray-300 text-primary focus:ring-primary"
            )
            span(class: "text-sm") { option[:label] }
          end
        end

        def render_notification_time_field
          render RubyUI::FormField.new do
            render RubyUI::FormFieldLabel.new(for: "payment_reminder_notification_time") { "Push Notification Time (Optional)" }
            render RubyUI::Input.new(
              type: :time,
              id: "payment_reminder_notification_time",
              name: "payment_reminder[notification_time]",
              value: @payment_reminder.notification_time&.strftime("%H:%M")
            )
            p(class: "text-xs text-muted-foreground mt-1") { "Receive a push notification at this time on reminder days" }
            render RubyUI::FormFieldError.new
          end
        end

        def render_active_field
          # Default to active for new reminders
          is_active = @payment_reminder.persisted? ? @payment_reminder.active? : true

          render RubyUI::FormField.new do
            # Hidden field MUST come BEFORE checkbox so Rails uses checkbox value when checked
            render RubyUI::Input.new(
              type: :hidden,
              name: "payment_reminder[active]",
              value: "0"
            )
            label(class: "flex items-center gap-2 cursor-pointer") do
              input(
                type: "checkbox",
                name: "payment_reminder[active]",
                value: "1",
                checked: is_active,
                class: "h-4 w-4 rounded border-gray-300 text-primary focus:ring-primary"
              )
              span(class: "text-sm font-medium") { "Active" }
            end
            p(class: "text-xs text-muted-foreground mt-1") { "Disable to pause reminders without deleting" }
          end
        end

        def render_actions
          div(class: "flex gap-2 justify-end mt-6") do
            Button(variant: :outline, type: "button", data: { action: "click->modal-form#cancelDialog" }) { "Cancel" }
            Button(variant: :primary, type: "submit") { submit_button_text }
          end
        end

        def format_number_for_input(number)
          return nil if number.nil?
          # Convert to float first to handle scientific notation, then format with 2 decimal places
          sprintf("%.2f", number.to_f)
        end
      end
    end
  end
end
