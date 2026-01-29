# frozen_string_literal: true

module Banking
  class BankAccountsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_bank_account, only: [ :edit, :update, :destroy ]
    layout -> { ::Views::Layouts::AppLayout.new(pathname: request.path) if request.format.html? }

    def index
      @bank_accounts = load_bank_accounts_with_counts

      respond_to do |format|
        format.turbo_stream do
          if params[:content_only]
            render turbo_stream: turbo_stream.replace(
              "bank_accounts_content",
              render_to_string(::Views::Banking::BankAccounts::List.new(bank_accounts: @bank_accounts), layout: false)
            )
          else
            render turbo_stream: turbo_stream.append(
              "body",
              render_to_string(::Views::Banking::BankAccounts::IndexDialog.new(bank_accounts: @bank_accounts), layout: false)
            )
          end
        end
      end
    end

    def new
      @bank_account = current_user.bank_accounts.build

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "bank_accounts_content",
            render_to_string(::Views::Banking::BankAccounts::Form.new(bank_account: @bank_account), layout: false)
          )
        end
      end
    end

    def create
      @bank_account = current_user.bank_accounts.build(bank_account_params)

      if @bank_account.save
        @bank_accounts = load_bank_accounts_with_counts
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "bank_accounts_content",
              render_to_string(::Views::Banking::BankAccounts::List.new(bank_accounts: @bank_accounts), layout: false)
            )
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "bank_account_form_errors",
              "<div class='text-sm text-destructive'>#{@bank_account.errors.full_messages.join(', ')}</div>"
            ), status: :unprocessable_entity
          end
        end
      end
    end

    def edit
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "bank_accounts_content",
            render_to_string(::Views::Banking::BankAccounts::Form.new(bank_account: @bank_account), layout: false)
          )
        end
      end
    end

    def update
      if @bank_account.update(bank_account_params)
        @bank_accounts = load_bank_accounts_with_counts
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "bank_accounts_content",
              render_to_string(::Views::Banking::BankAccounts::List.new(bank_accounts: @bank_accounts), layout: false)
            )
          end
        end
      else
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "bank_account_form_errors",
              "<div class='text-sm text-destructive'>#{@bank_account.errors.full_messages.join(', ')}</div>"
            ), status: :unprocessable_entity
          end
        end
      end
    end

    def destroy
      @bank_account.destroy!
      @bank_accounts = load_bank_accounts_with_counts

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "bank_accounts_content",
            render_to_string(::Views::Banking::BankAccounts::List.new(bank_accounts: @bank_accounts), layout: false)
          )
        end
      end
    end

    private

    def set_bank_account
      @bank_account = current_user.bank_accounts.find(params[:id])
    end

    def load_bank_accounts_with_counts
      current_user.bank_accounts
        .left_joins(:bank_transactions)
        .select("bank_accounts.*, COUNT(bank_transactions.id) AS transactions_count")
        .group("bank_accounts.id")
        .order(:name)
    end

    def bank_account_params
      params.require(:bank_account).permit(:name, :account_type, :active, :letter, :bg_color, :fg_color)
    end
  end
end
