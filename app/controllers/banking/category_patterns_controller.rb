# frozen_string_literal: true

module Banking
  class CategoryPatternsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_category_pattern, only: [ :edit, :update, :destroy ]
    layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) if request.format.html? }

    def index
      @category_patterns = current_user.category_patterns.includes(:category).order(:pattern)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.append(
            "body",
            render_to_string(::Views::Banking::CategoryPatterns::IndexDialog.new(category_patterns: @category_patterns), layout: false)
          )
        end
      end
    end

    def new
      @transaction = find_transaction_if_provided
      @category_pattern = current_user.category_patterns.build(
        pattern: @transaction&.description,
        category_id: @transaction&.category_id
      )
      @categories = current_user.categories.order(:name)

      respond_to do |format|
        format.turbo_stream do
          if params[:from_list]
            render turbo_stream: turbo_stream.replace(
              "category_patterns_content",
              render_to_string(::Views::Banking::CategoryPatterns::Form.new(
                category_pattern: @category_pattern,
                categories: @categories
              ), layout: false)
            )
          else
            render turbo_stream: turbo_stream.append(
              "body",
              render_to_string(::Views::Banking::CategoryPatterns::FormDialog.new(
                category_pattern: @category_pattern,
                categories: @categories,
                transaction: @transaction,
                filter_params: filter_params
              ), layout: false)
            )
          end
        end
      end
    end

    def create
      @category_pattern = current_user.category_patterns.build(category_pattern_params)

      if @category_pattern.save
        applied_count = apply_to_existing_if_requested

        respond_to do |format|
          format.turbo_stream do
            if params[:from_list]
              @category_patterns = current_user.category_patterns.includes(:category).order(:pattern)
              render turbo_stream: turbo_stream.replace(
                "category_patterns_content",
                render_to_string(::Views::Banking::CategoryPatterns::List.new(category_patterns: @category_patterns), layout: false)
              )
            else
              streams = [ turbo_stream.remove("category_pattern_dialog") ]
              if applied_count.positive?
                toast_message = "Pattern created and applied to #{applied_count} existing transaction#{'s' if applied_count != 1}"
                streams << turbo_stream.append(
                  "body",
                  "<script>window.toast && window.toast('#{toast_message}', { type: 'success' })</script>"
                )
                streams << turbo_stream.replace(
                  "transactions_list",
                  render_to_string(build_transactions_list, layout: false)
                )
              end
              render turbo_stream: streams
            end
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "category_pattern_form_errors",
              "<div class='text-sm text-destructive'>#{@category_pattern.errors.full_messages.join(', ')}</div>"
            ), status: :unprocessable_entity
          end
        end
      end
    end

    def edit
      @categories = current_user.categories.order(:name)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "category_patterns_content",
            render_to_string(::Views::Banking::CategoryPatterns::Form.new(
              category_pattern: @category_pattern,
              categories: @categories
            ), layout: false)
          )
        end
      end
    end

    def update
      if @category_pattern.update(category_pattern_params)
        @category_patterns = current_user.category_patterns.includes(:category).order(:pattern)
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "category_patterns_content",
              render_to_string(::Views::Banking::CategoryPatterns::List.new(category_patterns: @category_patterns), layout: false)
            )
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "category_pattern_form_errors",
              "<div class='text-sm text-destructive'>#{@category_pattern.errors.full_messages.join(', ')}</div>"
            ), status: :unprocessable_entity
          end
        end
      end
    end

    def destroy
      @category_pattern.destroy!
      @category_patterns = current_user.category_patterns.includes(:category).order(:pattern)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "category_patterns_content",
            render_to_string(::Views::Banking::CategoryPatterns::List.new(category_patterns: @category_patterns), layout: false)
          )
        end
      end
    end

    private

    def set_category_pattern
      @category_pattern = current_user.category_patterns.find(params[:id])
    end

    def find_transaction_if_provided
      return nil if params[:transaction_id].blank?

      current_user.bank_transactions.find_by(id: params[:transaction_id])
    end

    def category_pattern_params
      params.require(:category_pattern).permit(:pattern, :category_id)
    end

    def apply_to_existing_if_requested
      return 0 unless params[:apply_to_existing] == "1"

      matching_transactions = current_user.bank_transactions
        .where(category_id: nil)
        .where("LOWER(description) LIKE ?", "%#{@category_pattern.pattern.downcase}%")

      count = matching_transactions.count
      matching_transactions.update_all(category_id: @category_pattern.category_id)
      count
    end

    def filter_params
      params.permit(:page, :start_date, :end_date, :sort, :direction, :category_id, :min_amount, :max_amount, :search).to_h
    end

    def build_transactions_list
      fp = params[:filter] || {}
      page = fp[:page] || 1
      start_date = parse_date_param(fp[:start_date])
      end_date = parse_date_param(fp[:end_date])
      sort_column = %w[date description category value].include?(fp[:sort]) ? fp[:sort] : "date"
      sort_direction = %w[asc desc].include?(fp[:direction]) ? fp[:direction] : "desc"
      category_id = fp[:category_id]
      min_amount = fp[:min_amount]
      max_amount = fp[:max_amount]
      search = fp[:search]

      transactions = current_user.bank_transactions.includes(:category)
      transactions = transactions.where(date: start_date..end_date) if start_date && end_date
      transactions = transactions.where("date >= ?", start_date) if start_date && !end_date
      transactions = transactions.where("date <= ?", end_date) if end_date && !start_date
      transactions = apply_category_filter_for_list(transactions, category_id)
      transactions = apply_amount_filters_for_list(transactions, min_amount, max_amount)
      transactions = transactions.where("LOWER(description) LIKE ?", "%#{search.downcase}%") if search.present?
      transactions = apply_sorting_for_list(transactions, sort_column, sort_direction)
      transactions = transactions.page(page).per(100)

      ::Views::Banking::TransactionsList.new(
        user: current_user,
        transactions: transactions,
        page: page,
        start_date: start_date,
        end_date: end_date,
        sort_column: sort_column,
        sort_direction: sort_direction,
        category_id: category_id,
        min_amount: min_amount,
        max_amount: max_amount,
        search: search
      )
    end

    def parse_date_param(param)
      return nil if param.blank? || param == "all"
      param.to_date
    rescue ArgumentError
      nil
    end

    def apply_category_filter_for_list(transactions, category_id)
      return transactions if category_id.blank?
      category_id == "uncategorized" ? transactions.where(category_id: nil) : transactions.where(category_id: category_id)
    end

    def apply_amount_filters_for_list(transactions, min_amount, max_amount)
      transactions = transactions.where("ABS(value) >= ?", BigDecimal(min_amount)) if min_amount.present?
      transactions = transactions.where("ABS(value) <= ?", BigDecimal(max_amount)) if max_amount.present?
      transactions
    end

    def apply_sorting_for_list(transactions, sort_column, sort_direction)
      case sort_column
      when "category"
        transactions.left_joins(:category).order(Arel.sql("categories.name #{sort_direction} NULLS LAST, bank_transactions.id DESC"))
      when "date"
        transactions.order(date: sort_direction.to_sym, id: :desc)
      when "description"
        transactions.order(description: sort_direction.to_sym, id: :desc)
      when "value"
        transactions.order(value: sort_direction.to_sym, id: :desc)
      else
        transactions.order(date: :desc, id: :desc)
      end
    end
  end
end
