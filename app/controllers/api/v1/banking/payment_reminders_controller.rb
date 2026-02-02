# frozen_string_literal: true

module Api
  module V1
    module Banking
      class PaymentRemindersController < Api::BaseController
        before_action :authorize_banking_access!

        resource_description do
          short "Payment Reminders"
          description "Manage payment reminders"
          meta group: "Banking"
          formats [ "json" ]
        end

        api :GET, "/banking/payment_reminders", "List payment reminders"
        description "Returns payment reminders with optional active filter."
        param :active, String, desc: "Filter by active status (true/false)", required: false
        def index
          reminders = current_user.payment_reminders.order(cutoff_date: :asc)
          reminders = reminders.where(active: params[:active] == "true") if params[:active].present?

          render json: {
            data: reminders.map { |r| serialize_payment_reminder(r) },
            meta: { total_count: reminders.count }
          }, status: :ok
        end

        api :GET, "/banking/payment_reminders/:id", "Show a payment reminder"
        param :id, :number, desc: "Payment reminder ID", required: true
        def show
          reminder = current_user.payment_reminders.includes(:day_payment_reminders).find(params[:id])
          paid_at = reminder.day_payment_reminders
            .select { |dpr| dpr.paid_at.present? }
            .max_by(&:paid_at)&.paid_at

          render json: {
            data: serialize_payment_reminder(reminder).merge(
              paid_at: paid_at&.iso8601
            ),
            meta: {}
          }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        api :POST, "/banking/payment_reminders", "Create a payment reminder"
        param :payment_reminder, Hash, desc: "Payment reminder attributes", required: true do
          param :title, String, desc: "Reminder title", required: true
          param :expected_amount, :number, desc: "Expected payment amount", required: false
          param :cutoff_date, String, desc: "Payment due date (YYYY-MM-DD)", required: true
          param :payment_url, String, desc: "URL for making the payment", required: false
          param :active, :boolean, desc: "Whether reminder is active", required: false
          param :notification_time, String, desc: "Time to send notification (HH:MM)", required: false
          param :reminder_days_before, Array, of: :number, desc: "Days before cutoff to remind", required: false
        end
        def create
          reminder = current_user.payment_reminders.build(payment_reminder_params)

          if reminder.save
            ::Banking::PaymentReminderProcessorService.new(current_user).process_single(reminder)

            render json: {
              data: serialize_payment_reminder(reminder),
              meta: {}
            }, status: :created
          else
            render_error(
              reminder.errors.full_messages.join(", "),
              status: :unprocessable_entity,
              errors: reminder.errors.full_messages
            )
          end
        end

        api :PATCH, "/banking/payment_reminders/:id", "Update a payment reminder"
        param :id, :number, desc: "Payment reminder ID", required: true
        param :payment_reminder, Hash, desc: "Payment reminder attributes", required: true do
          param :title, String, desc: "Reminder title", required: false
          param :expected_amount, :number, desc: "Expected payment amount", required: false
          param :cutoff_date, String, desc: "Payment due date", required: false
          param :payment_url, String, desc: "Payment URL", required: false
          param :active, :boolean, desc: "Whether reminder is active", required: false
          param :notification_time, String, desc: "Notification time", required: false
          param :reminder_days_before, Array, of: :number, desc: "Reminder days", required: false
        end
        def update
          reminder = current_user.payment_reminders.find(params[:id])

          if reminder.update(payment_reminder_params)
            ::Banking::PaymentReminderProcessorService.new(current_user).process_single(reminder)

            render json: {
              data: serialize_payment_reminder(reminder),
              meta: {}
            }, status: :ok
          else
            render_error(
              reminder.errors.full_messages.join(", "),
              status: :unprocessable_entity,
              errors: reminder.errors.full_messages
            )
          end
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        api :DELETE, "/banking/payment_reminders/:id", "Delete a payment reminder"
        param :id, :number, desc: "Payment reminder ID", required: true
        def destroy
          reminder = current_user.payment_reminders.find(params[:id])
          reminder.destroy!

          render json: { data: nil, meta: {} }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        api :POST, "/banking/payment_reminders/:id/clone", "Clone a payment reminder"
        description "Creates a new payment reminder from an existing one with a new cutoff date."
        param :id, :number, desc: "Payment reminder ID to clone", required: true
        def clone
          original = current_user.payment_reminders.find(params[:id])

          reminder_days = if original.reminder_days_before.is_a?(Array)
            original.reminder_days_before.dup
          elsif original.reminder_days_before.present?
            Array(original.reminder_days_before)
          else
            [ 7, 3, 0 ]
          end

          cloned = current_user.payment_reminders.create!(
            title: original.title,
            expected_amount: original.expected_amount,
            cutoff_date: Date.current + 30.days,
            payment_url: original.payment_url,
            reminder_days_before: reminder_days,
            notification_time: original.notification_time,
            active: original.active
          )

          render json: {
            data: serialize_payment_reminder(cloned),
            meta: {}
          }, status: :created
        rescue ActiveRecord::RecordNotFound
          render_not_found
        rescue ActiveRecord::RecordInvalid => e
          render_error(
            e.record.errors.full_messages.join(", "),
            status: :unprocessable_entity,
            errors: e.record.errors.full_messages
          )
        end

        private

        def authorize_banking_access!
          authorize_feature!(:banking)
        end

        def payment_reminder_params
          params.require(:payment_reminder).permit(:title, :expected_amount, :cutoff_date, :payment_url, :active, :notification_time, reminder_days_before: [])
        end

        def serialize_payment_reminder(reminder)
          {
            id: reminder.id,
            title: reminder.title,
            expected_amount: reminder.expected_amount&.to_f,
            cutoff_date: reminder.cutoff_date&.to_s,
            payment_url: reminder.payment_url,
            active: reminder.active,
            notification_time: reminder.notification_time&.strftime("%H:%M"),
            reminder_days_before: reminder.reminder_days_before,
            created_at: reminder.created_at.iso8601,
            updated_at: reminder.updated_at.iso8601
          }
        end
      end
    end
  end
end
