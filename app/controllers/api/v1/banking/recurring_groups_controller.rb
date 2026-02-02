# frozen_string_literal: true

module Api
  module V1
    module Banking
      class RecurringGroupsController < Api::BaseController
        before_action :authorize_banking_access!

        resource_description do
          short "Recurring Groups"
          description "View recurring transaction groups"
          meta group: "Banking"
          formats [ "json" ]
        end

        api :GET, "/banking/recurring_groups", "List recurring groups"
        description "Returns active recurring groups with monthly amounts."
        def index
          groups = current_user.recurring_groups.active.by_last_occurrence.includes(:bank_transactions)
          total_monthly = groups.sum(&:monthly_amount).to_f.round(2)

          render json: {
            data: groups.map { |g| serialize_recurring_group(g) },
            meta: {
              total_count: groups.length,
              total_monthly: total_monthly
            }
          }, status: :ok
        end

        api :GET, "/banking/recurring_groups/:id", "Show a recurring group"
        description "Returns a recurring group with its linked transactions."
        param :id, :number, desc: "Recurring group ID", required: true
        def show
          group = current_user.recurring_groups.find(params[:id])
          transactions = group.bank_transactions.order(date: :desc)

          render json: {
            data: serialize_recurring_group(group).merge(
              transactions: transactions.map { |t| serialize_group_transaction(t) }
            ),
            meta: {}
          }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        api :POST, "/banking/recurring_groups/detect", "Detect recurring transactions"
        description "Starts async detection of recurring transaction patterns. Returns 202."
        def detect
          ::Banking::RecurringDetectionJob.perform_later(current_user.id)

          render json: {
            data: nil,
            meta: { message: "Recurring detection started. Processing will happen in the background." }
          }, status: :accepted
        end

        private

        def authorize_banking_access!
          authorize_feature!(:banking)
        end

        def serialize_recurring_group(group)
          {
            id: group.id,
            name: group.name,
            average_amount: group.average_amount&.to_f,
            monthly_amount: group.monthly_amount&.to_f,
            frequency: group.frequency,
            active: group.active,
            transaction_count: group.bank_transactions.loaded? ? group.bank_transactions.size : group.bank_transactions.count,
            created_at: group.created_at.iso8601,
            updated_at: group.updated_at.iso8601
          }
        end

        def serialize_group_transaction(transaction)
          {
            id: transaction.id,
            date: transaction.date.to_s,
            description: transaction.description,
            value: transaction.value.to_f
          }
        end
      end
    end
  end
end
