# frozen_string_literal: true

class BankingController < ApplicationController
  before_action :authenticate_user!
  before_action { authorize! :access, :banking }
  layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) if request.format.html? }

  def new_transaction
    @transaction = current_user.bank_transactions.build(date: Date.current)
    @categories = current_user.categories.top_level.with_subcategories.order(:name)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "body",
          render_to_string(::Views::Banking::TransactionFormDialog.new(
            transaction: @transaction,
            categories: @categories
          ), layout: false)
        )
      end
    end
  end

  def new_csv_import
    @bank_accounts = current_user.bank_accounts.active.ordered

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "body",
          render_to_string(::Views::Banking::CsvImportDialog.new(bank_accounts: @bank_accounts), layout: false)
        )
      end
    end
  end

  def import_csv
    csv_file = params[:csv_file]

    if csv_file.blank?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "csv_import_form_errors",
            "<div class='text-sm text-destructive'>Please select a CSV file</div>"
          ), status: :unprocessable_entity
        end
      end
      return
    end

    csv_content = csv_file.read
    bank_account_id = params[:bank_account_id].presence

    Banking::ImportJob.perform_later(current_user.id, csv_content, bank_account_id: bank_account_id)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove("csv_import_dialog")
      end
    end
  end

  def toggle_transfer
    @transaction = current_user.bank_transactions.find(params[:id])
    new_transfer_state = !@transaction.is_transfer
    @transaction.update!(is_transfer: new_transfer_state)

    # Manage Transfers category
    transfers_category = current_user.categories.find_or_create_by!(name: "Transfers") do |cat|
      cat.color = "#109648"
    end

    if new_transfer_state
      @transaction.transaction_categorizations.find_or_create_by!(category: transfers_category) do |tc|
        tc.user = current_user
      end
    else
      @transaction.transaction_categorizations.where(category: transfers_category).destroy_all
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "transaction_#{@transaction.id}",
          render_to_string(::Views::Banking::TransactionRow.new(
            transaction: @transaction.reload,
            categories: current_user.categories.top_level.with_subcategories.order(:name)
          ), layout: false)
        )
      end
    end
  end

  def create_transaction
    @transaction = current_user.bank_transactions.build(transaction_params)
    @transaction.row_hash = ::Banking::TransactionRowHashService.generate_from_transaction(@transaction)

    if @transaction.save
      # Handle category assignment via transaction_categorizations
      category_id = params[:category_id]
      if category_id.present?
        @transaction.set_categories([ category_id ])
      end

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend(
            "transactions_table_body",
            render_to_string(::Views::Banking::TransactionRow.new(
              transaction: @transaction.reload,
              categories: current_user.categories.top_level.with_subcategories.order(:name)
            ), layout: false)
          )
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "transaction_form_errors",
            "<div class='text-sm text-destructive'>#{@transaction.errors.full_messages.join(', ')}</div>"
          ), status: :unprocessable_entity
        end
      end
    end
  end

  def edit_transaction
    @transaction = current_user.bank_transactions.find(params[:id])
    @categories = current_user.categories.top_level.with_subcategories.order(:name)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "body",
          render_to_string(::Views::Banking::TransactionFormDialog.new(
            transaction: @transaction,
            categories: @categories
          ), layout: false)
        )
      end
    end
  end

  def update_transaction
    @transaction = current_user.bank_transactions.find(params[:id])

    if @transaction.update(transaction_params)
      @transaction.update_column(:row_hash, ::Banking::TransactionRowHashService.generate_from_transaction(@transaction))

      # Handle category assignment via transaction_categorizations
      category_id = params[:category_id]
      if category_id.present?
        @transaction.set_categories([ category_id ])
      elsif category_id == ""
        @transaction.transaction_categorizations.destroy_all
      end

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "transaction_#{@transaction.id}",
            render_to_string(::Views::Banking::TransactionRow.new(
              transaction: @transaction.reload,
              categories: current_user.categories.top_level.with_subcategories.order(:name)
            ), layout: false)
          )
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "transaction_form_errors",
            "<div class='text-sm text-destructive'>#{@transaction.errors.full_messages.join(', ')}</div>"
          ), status: :unprocessable_entity
        end
      end
    end
  end

  def update_category
    @transaction = current_user.bank_transactions.find(params[:id])
    @categories = current_user.categories.top_level.with_subcategories.order(:name)

    category_id = params.dig(:bank_transaction, :category_id)
    category_id = nil if category_id.blank?

    # Update using set_categories for proper categorization handling
    if category_id.present?
      @transaction.set_categories([ category_id ])
    else
      @transaction.transaction_categorizations.destroy_all
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "transaction_#{@transaction.id}_category",
          render_to_string(::Views::Banking::CategorySelector.new(
            transaction: @transaction.reload,
            categories: @categories,
            show_success: true
          ), layout: false)
        )
      end
    end
  rescue StandardError => e
    respond_to do |format|
      format.turbo_stream do
        head :unprocessable_entity
      end
    end
  end

  def edit_categories
    @transaction = current_user.bank_transactions.find(params[:id])
    @categories = current_user.categories.top_level.with_subcategories.order(:name)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "body",
          render_to_string(::Views::Banking::MultiCategoryDialog.new(
            transaction: @transaction,
            categories: @categories
          ), layout: false)
        )
      end
    end
  end

  def update_categories
    @transaction = current_user.bank_transactions.find(params[:id])
    @categories = current_user.categories.top_level.with_subcategories.order(:name)

    category_ids = params[:category_ids]&.reject(&:blank?) || []
    amounts = params[:amounts] || {}

    @transaction.set_categories(category_ids, amounts)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove("multi_category_dialog"),
          turbo_stream.replace(
            "transaction_#{@transaction.id}_category",
            render_to_string(::Views::Banking::CategorySelector.new(
              transaction: @transaction.reload,
              categories: @categories,
              show_success: true
            ), layout: false)
          )
        ]
      end
    end
  rescue StandardError => e
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "multi_category_form_errors",
          "<div class='text-sm text-destructive'>#{e.message}</div>"
        ), status: :unprocessable_entity
      end
    end
  end

  def destroy_transaction
    @transaction = current_user.bank_transactions.find(params[:id])
    @transaction.destroy!

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove("transaction_#{@transaction.id}")
      end
    end
  end

  def bulk_destroy
    ids = params[:ids].to_s.split(",").map(&:to_i)
    transactions = current_user.bank_transactions.where(id: ids)
    transaction_ids = transactions.pluck(:id)
    transactions.destroy_all

    respond_to do |format|
      format.turbo_stream do
        streams = transaction_ids.map do |id|
          turbo_stream.remove("transaction_#{id}")
        end
        render turbo_stream: streams
      end
    end
  end

  def index
    query_service = ::Banking::TransactionQueryService.new(current_user, query_params)
    result = query_service.call

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "transactions_list",
          render_to_string(::Views::Banking::TransactionsList.new(
            user: current_user,
            transactions: result.transactions,
            page: query_service.page,
            start_date: query_service.start_date,
            end_date: query_service.end_date,
            sort_column: query_service.sort_column,
            sort_direction: query_service.sort_direction,
            category_id: query_service.category_id,
            min_amount: query_service.min_amount,
            max_amount: query_service.max_amount,
            search: query_service.search,
            bank_account_id: query_service.bank_account_id
          ), layout: false)
        )
      end
      format.html do
        render ::Views::Banking::Index.new(
          user: current_user,
          start_date: query_service.start_date,
          end_date: query_service.end_date,
          total_income: result.total_income,
          total_expenses: result.total_expenses,
          net_balance: result.net_balance,
          total_transfers: result.total_transfers,
          income_change: result.income_change,
          expenses_change: result.expenses_change,
          balance_change: result.balance_change,
          category_breakdown: result.category_breakdown,
          time_series_data: result.time_series_data,
          time_series_granularity: result.time_series_granularity,
          transfers_time_series_data: result.transfers_time_series_data,
          transactions: result.transactions,
          page: query_service.page,
          sort_column: query_service.sort_column,
          sort_direction: query_service.sort_direction,
          category_id: query_service.category_id,
          breakdown_parent_id: query_service.breakdown_parent_id,
          min_amount: query_service.min_amount,
          max_amount: query_service.max_amount,
          search: query_service.search,
          bank_account_id: query_service.bank_account_id
        )
      end
    end
  end

  private

  def transaction_params
    params.require(:bank_transaction).permit(:date, :description, :value)
  end

  def query_params
    params.permit(:start_date, :end_date, :page, :sort, :direction, :category_id,
                  :breakdown_parent_id, :min_amount, :max_amount, :search,
                  :bank_account_id).to_h.symbolize_keys
  end
end
