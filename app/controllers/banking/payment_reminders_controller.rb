# frozen_string_literal: true

module Banking
  class PaymentRemindersController < BaseController
    before_action :set_payment_reminder, only: [ :edit, :update, :destroy, :clone ]
    layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) if request.format.html? }

    def index
      @payment_reminders = current_user.payment_reminders.order(cutoff_date: :asc)

      respond_to do |format|
        format.html { redirect_to banking_forecasts_path }
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "body",
            render_to_string(::Views::Banking::PaymentReminders::IndexDialog.new(
              payment_reminders: @payment_reminders
            ), layout: false)
          )
        end
      end
    end

    def new
      @payment_reminder = current_user.payment_reminders.build(
        title: params[:title],
        cutoff_date: Date.current + 30.days,
        payment_url: params[:payment_url],
        reminder_days_before: params[:reminder_days_before] || [ 7, 3, 0 ],
        active: params[:active].nil? ? true : params[:active] == "true"
      )

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "body",
            render_to_string(::Views::Banking::PaymentReminders::FormDialog.new(
              payment_reminder: @payment_reminder
            ), layout: false)
          )
        end
      end
    end

    def create
      @payment_reminder = current_user.payment_reminders.build(payment_reminder_params)

      if @payment_reminder.save
        # Immediately process for today (creates DayPaymentReminder and schedules notification)
        Banking::PaymentReminderProcessorService.new(current_user).process_single(@payment_reminder)

        respond_to do |format|
          format.turbo_stream do
            streams = [
              turbo_stream.remove("payment_reminder_form_dialog"),
              turbo_stream.replace(
                "payment_reminders_content",
                render_to_string(::Views::Banking::PaymentReminders::TabsContent.new(
                  payment_reminders: all_reminders
                ), layout: false)
              )
            ]
            # Update forecast view if it exists on the page
            streams << turbo_stream.replace(
              "forecast_main_content",
              render_forecast_main_content
            ) if forecast_view_exists?
            render turbo_stream: streams
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "payment_reminder_form_errors",
              "<div class='text-sm text-destructive'>#{@payment_reminder.errors.full_messages.join(', ')}</div>"
            ), status: :unprocessable_entity
          end
        end
      end
    end

    def edit
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "body",
            render_to_string(::Views::Banking::PaymentReminders::FormDialog.new(
              payment_reminder: @payment_reminder
            ), layout: false)
          )
        end
      end
    end

    def update
      if @payment_reminder.update(payment_reminder_params)
        # Re-process for today (schedules notification if not already done)
        Banking::PaymentReminderProcessorService.new(current_user).process_single(@payment_reminder)

        respond_to do |format|
          format.turbo_stream do
            streams = [
              turbo_stream.remove("payment_reminder_form_dialog"),
              turbo_stream.replace(
                "payment_reminders_content",
                render_to_string(::Views::Banking::PaymentReminders::TabsContent.new(
                  payment_reminders: all_reminders
                ), layout: false)
              )
            ]
            # Update forecast view if it exists on the page
            streams << turbo_stream.replace(
              "forecast_main_content",
              render_forecast_main_content
            ) if forecast_view_exists?
            render turbo_stream: streams
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "payment_reminder_form_errors",
              "<div class='text-sm text-destructive'>#{@payment_reminder.errors.full_messages.join(', ')}</div>"
            ), status: :unprocessable_entity
          end
        end
      end
    end

    def destroy
      @payment_reminder.destroy!

      respond_to do |format|
        format.turbo_stream do
          streams = [
            turbo_stream.remove("payment_reminder_#{@payment_reminder.id}"),
            turbo_stream.replace(
              "payment_reminders_content",
              render_to_string(::Views::Banking::PaymentReminders::TabsContent.new(
                payment_reminders: all_reminders
              ), layout: false)
            )
          ]
          # Update forecast view if it exists on the page
          streams << turbo_stream.replace(
            "forecast_main_content",
            render_forecast_main_content
          ) if forecast_view_exists?
          render turbo_stream: streams
        end
      end
    end

    def clone
      # Open the create modal with pre-filled values from the original reminder
      original = @payment_reminder

      # Ensure reminder_days_before is an array
      reminder_days = if original.reminder_days_before.is_a?(Array)
        original.reminder_days_before.dup
      elsif original.reminder_days_before.present?
        Array(original.reminder_days_before)
      else
        [ 7, 3, 0 ]
      end

      @payment_reminder = current_user.payment_reminders.build(
        title: original.title,
        expected_amount: original.expected_amount,
        cutoff_date: Date.current + 30.days,
        payment_url: original.payment_url,
        reminder_days_before: reminder_days,
        notification_time: original.notification_time,
        active: original.active
      )

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "body",
            render_to_string(::Views::Banking::PaymentReminders::FormDialog.new(
              payment_reminder: @payment_reminder
            ), layout: false)
          )
        end
      end
    end

    private

    def set_payment_reminder
      @payment_reminder = current_user.payment_reminders.find(params[:id])
    end

    def payment_reminder_params
      params.require(:payment_reminder).permit(:title, :expected_amount, :cutoff_date, :payment_url, :active, :notification_time, reminder_days_before: [])
    end

    def all_reminders
      current_user.payment_reminders.order(cutoff_date: :asc)
    end

    def forecast_view_exists?
      # Check if forecast_main_content element exists in the DOM
      # This is a best-effort check - Turbo Streams will silently fail if element doesn't exist
      true
    end

    def render_forecast_main_content
      payment_reminders = current_user.payment_reminders.active.upcoming.includes(:day_payment_reminders)
      section_spending = ::Banking::SectionSpendingService.new(current_user).call

      # Build paid status hash using preloaded association
      paid_status = payment_reminders.each_with_object({}) do |reminder, status|
        paid_reminder = reminder.day_payment_reminders
          .select { |dpr| dpr.paid_at.present? }
          .max_by(&:paid_at)
        status[reminder.id] = paid_reminder&.paid_at
      end

      render_to_string(
        ::Views::Banking::Forecasts::MainContent.new(
          payment_reminders: payment_reminders,
          paid_status: paid_status,
          section_spending: section_spending
        ),
        layout: false
      )
    end
  end
end
