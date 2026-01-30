# frozen_string_literal: true

module Banking
  class RecurringGroupsController < BaseController
    layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) if request.format.html? }

    def index
      @recurring_groups = current_user.recurring_groups.active.by_last_occurrence.includes(:bank_transactions)

      respond_to do |format|
        format.turbo_stream do
          if params[:back_to_list]
            render turbo_stream: turbo_stream.replace(
              "recurring_groups_content",
              render_to_string(::Views::Banking::RecurringGroups::List.new(
                recurring_groups: @recurring_groups,
                total_monthly: calculate_total_monthly(@recurring_groups)
              ), layout: false)
            )
          else
            render turbo_stream: turbo_stream.append(
              "body",
              render_to_string(::Views::Banking::RecurringGroups::IndexDialog.new(
                recurring_groups: @recurring_groups,
                total_monthly: calculate_total_monthly(@recurring_groups)
              ), layout: false)
            )
          end
        end
      end
    end

    def show
      @recurring_group = current_user.recurring_groups.find(params[:id])
      @transactions = @recurring_group.bank_transactions.order(date: :desc)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "recurring_groups_content",
            render_to_string(::Views::Banking::RecurringGroups::TransactionsList.new(
              recurring_group: @recurring_group,
              transactions: @transactions
            ), layout: false)
          )
        end
      end
    end

    def detect
      ::Banking::RecurringDetectionJob.perform_later(current_user.id)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "recurring_detection_errors",
            "<div class='text-sm text-muted-foreground'>Detection started... You'll be notified when complete.</div>"
          )
        end
      end
    end

    private

    def calculate_total_monthly(groups)
      groups.sum(&:monthly_amount).round(2)
    end
  end
end
