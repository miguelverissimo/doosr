# frozen_string_literal: true

module Banking
  class PaymentRemindersController < ApplicationController
    before_action :authenticate_user!
    before_action :set_payment_reminder, only: [:edit, :update, :destroy, :clone]
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
        reminder_days_before: params[:reminder_days_before] || [7, 3, 0],
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
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.remove("payment_reminder_form_dialog"),
              turbo_stream.replace(
                "payment_reminders_content",
                render_to_string(::Views::Banking::PaymentReminders::TabsContent.new(
                  payment_reminders: all_reminders
                ), layout: false)
              )
            ]
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
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.remove("payment_reminder_form_dialog"),
              turbo_stream.replace(
                "payment_reminders_content",
                render_to_string(::Views::Banking::PaymentReminders::TabsContent.new(
                  payment_reminders: all_reminders
                ), layout: false)
              )
            ]
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
          render turbo_stream: [
            turbo_stream.remove("payment_reminder_#{@payment_reminder.id}"),
            turbo_stream.replace(
              "payment_reminders_content",
              render_to_string(::Views::Banking::PaymentReminders::TabsContent.new(
                payment_reminders: all_reminders
              ), layout: false)
            )
          ]
        end
      end
    end

    def clone
      # Open the create modal with pre-filled values from the original reminder
      @payment_reminder = current_user.payment_reminders.build(
        title: @payment_reminder.title,
        cutoff_date: Date.current + 30.days,
        payment_url: @payment_reminder.payment_url,
        reminder_days_before: @payment_reminder.reminder_days_before,
        active: @payment_reminder.active
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
      params.require(:payment_reminder).permit(:title, :cutoff_date, :payment_url, :active, reminder_days_before: [])
    end

    def all_reminders
      current_user.payment_reminders.order(cutoff_date: :asc)
    end
  end
end
