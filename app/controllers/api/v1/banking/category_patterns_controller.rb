# frozen_string_literal: true

module Api
  module V1
    module Banking
      class CategoryPatternsController < Api::BaseController
        before_action :authorize_banking_access!

        resource_description do
          short "Category Patterns"
          description "Manage category auto-assignment patterns"
          meta group: "Banking"
          formats [ "json" ]
        end

        api :GET, "/banking/category_patterns", "List category patterns"
        description "Returns category patterns with matched transaction counts and category info."
        def index
          patterns = current_user.category_patterns
            .includes(:category)
            .left_joins(:bank_transactions)
            .select("category_patterns.*, COUNT(bank_transactions.id) AS matched_transactions_count")
            .group("category_patterns.id")
            .order(:pattern)

          render json: {
            data: patterns.map { |p| serialize_pattern(p) },
            meta: { total_count: patterns.length }
          }, status: :ok
        end

        api :GET, "/banking/category_patterns/:id", "Show a category pattern"
        param :id, :number, desc: "Category pattern ID", required: true
        def show
          pattern = current_user.category_patterns.includes(:category).find(params[:id])
          matched_count = pattern.bank_transactions.count

          render json: {
            data: serialize_pattern(pattern, matched_count: matched_count),
            meta: {}
          }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        api :POST, "/banking/category_patterns", "Create a category pattern"
        param :category_pattern, Hash, desc: "Category pattern attributes", required: true do
          param :pattern, String, desc: "Pattern string to match against transaction descriptions", required: true
          param :label, String, desc: "Label for the pattern", required: false
          param :category_id, :number, desc: "Category ID to assign when matched", required: true
        end
        param :apply_to_existing, :boolean, desc: "Apply pattern to existing uncategorized transactions", required: false
        def create
          pattern = current_user.category_patterns.build(category_pattern_params)

          if pattern.save
            applied_count = 0
            if params[:apply_to_existing].present? && params[:apply_to_existing] != "0" && params[:apply_to_existing] != false
              applied_count = ::Banking::CategoryPatternMatcherService.new(current_user).apply_to_existing(pattern)
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

        api :PATCH, "/banking/category_patterns/:id", "Update a category pattern"
        description "Updates a category pattern and automatically rematches transactions."
        param :id, :number, desc: "Category pattern ID", required: true
        param :category_pattern, Hash, desc: "Category pattern attributes", required: true do
          param :pattern, String, desc: "Pattern string", required: false
          param :label, String, desc: "Label", required: false
          param :category_id, :number, desc: "Category ID", required: false
        end
        def update
          pattern = current_user.category_patterns.find(params[:id])

          if pattern.update(category_pattern_params)
            rematch_stats = ::Banking::CategoryPatternMatcherService.new(current_user).rematch(pattern)

            render json: {
              data: serialize_pattern(pattern),
              meta: { rematch_stats: rematch_stats }
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

        api :DELETE, "/banking/category_patterns/:id", "Delete a category pattern"
        param :id, :number, desc: "Category pattern ID", required: true
        def destroy
          pattern = current_user.category_patterns.find(params[:id])
          pattern.destroy!

          render json: { data: nil, meta: {} }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        private

        def authorize_banking_access!
          authorize_feature!(:banking)
        end

        def category_pattern_params
          params.require(:category_pattern).permit(:pattern, :label, :category_id)
        end

        def serialize_pattern(pattern, matched_count: nil)
          {
            id: pattern.id,
            pattern: pattern.pattern,
            label: pattern.label,
            category_id: pattern.category_id,
            category_name: pattern.category&.name,
            category_color: pattern.category&.color,
            matched_transactions_count: matched_count || (pattern.respond_to?(:matched_transactions_count) ? pattern.matched_transactions_count : nil),
            created_at: pattern.created_at.iso8601,
            updated_at: pattern.updated_at.iso8601
          }
        end
      end
    end
  end
end
