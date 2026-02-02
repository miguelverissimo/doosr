# frozen_string_literal: true

module Api
  module V1
    module Banking
      class TransferPatternsController < Api::BaseController
        before_action :authorize_banking_access!

        resource_description do
          short "Transfer Patterns"
          description "Manage transfer auto-detection patterns"
          meta group: "Banking"
          formats [ "json" ]
        end

        api :GET, "/banking/transfer_patterns", "List transfer patterns"
        description "Returns transfer patterns with matched transaction counts."
        def index
          patterns = ::Banking::TransferPatternQueryService.new(current_user).call

          render json: {
            data: patterns.map { |p| serialize_pattern(p) },
            meta: { total_count: patterns.length }
          }, status: :ok
        end

        api :GET, "/banking/transfer_patterns/:id", "Show a transfer pattern"
        param :id, :number, desc: "Transfer pattern ID", required: true
        def show
          pattern = current_user.transfer_patterns.find(params[:id])
          matched_count = current_user.bank_transactions
            .where(is_transfer: true)
            .where("LOWER(description) LIKE ?", "%#{pattern.pattern.downcase}%")
            .count

          render json: {
            data: serialize_pattern(pattern, matched_count: matched_count),
            meta: {}
          }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        api :POST, "/banking/transfer_patterns", "Create a transfer pattern"
        param :transfer_pattern, Hash, desc: "Transfer pattern attributes", required: true do
          param :pattern, String, desc: "Pattern string to match against transaction descriptions", required: true
          param :label, String, desc: "Label for the pattern", required: false
        end
        param :apply_to_existing, :boolean, desc: "Apply pattern to existing non-transfer transactions", required: false
        def create
          pattern = current_user.transfer_patterns.build(transfer_pattern_params)

          if pattern.save
            applied_count = 0
            if params[:apply_to_existing].present? && params[:apply_to_existing] != "0" && params[:apply_to_existing] != false
              applied_count = ::Banking::TransferPatternMatcherService.new(current_user).apply_to_existing(pattern)
            end

            render json: {
              data: serialize_pattern(pattern),
              meta: { applied_count: applied_count }
            }, status: :created
          else
            render_error(
              pattern.errors.full_messages.join(", "),
              status: :unprocessable_entity,
              errors: pattern.errors.full_messages
            )
          end
        end

        api :PATCH, "/banking/transfer_patterns/:id", "Update a transfer pattern"
        description "Updates a transfer pattern and automatically rematches transactions."
        param :id, :number, desc: "Transfer pattern ID", required: true
        param :transfer_pattern, Hash, desc: "Transfer pattern attributes", required: true do
          param :pattern, String, desc: "Pattern string", required: false
          param :label, String, desc: "Label", required: false
        end
        def update
          pattern = current_user.transfer_patterns.find(params[:id])

          if pattern.update(transfer_pattern_params)
            applied_count = ::Banking::TransferPatternMatcherService.new(current_user).rematch(pattern)

            render json: {
              data: serialize_pattern(pattern),
              meta: { applied_count: applied_count }
            }, status: :ok
          else
            render_error(
              pattern.errors.full_messages.join(", "),
              status: :unprocessable_entity,
              errors: pattern.errors.full_messages
            )
          end
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        api :DELETE, "/banking/transfer_patterns/:id", "Delete a transfer pattern"
        description "Deletes a transfer pattern and unmarks matching transactions."
        param :id, :number, desc: "Transfer pattern ID", required: true
        def destroy
          pattern = current_user.transfer_patterns.find(params[:id])
          ::Banking::TransferPatternMatcherService.new(current_user).unmark_matching(pattern)
          pattern.destroy!

          render json: { data: nil, meta: {} }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        private

        def authorize_banking_access!
          authorize_feature!(:banking)
        end

        def transfer_pattern_params
          params.require(:transfer_pattern).permit(:pattern, :label)
        end

        def serialize_pattern(pattern, matched_count: nil)
          {
            id: pattern.id,
            pattern: pattern.pattern,
            label: pattern.label,
            matched_transactions_count: matched_count || (pattern.respond_to?(:matched_transactions_count) ? pattern.matched_transactions_count : nil),
            created_at: pattern.created_at.iso8601,
            updated_at: pattern.updated_at.iso8601
          }
        end
      end
    end
  end
end
