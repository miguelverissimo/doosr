# frozen_string_literal: true

module Api
  module V1
    module Banking
      class BankAccountsController < Api::BaseController
        before_action :authorize_banking_access!

        resource_description do
          short "Bank Accounts"
          description "Manage bank accounts"
          meta group: "Banking"
          formats [ "json" ]
        end

        api :GET, "/banking/bank_accounts", "List bank accounts"
        description "Returns bank accounts with transaction counts."
        param :active, String, desc: "Filter by active status (true/false)", required: false
        def index
          accounts = current_user.bank_accounts
            .left_joins(:bank_transactions)
            .select("bank_accounts.*, COUNT(bank_transactions.id) AS transactions_count")
            .group("bank_accounts.id")
            .order(:name)

          accounts = accounts.where(active: params[:active] == "true") if params[:active].present?

          render json: {
            data: accounts.map { |a| serialize_bank_account(a) },
            meta: { total_count: accounts.length }
          }, status: :ok
        end

        api :GET, "/banking/bank_accounts/:id", "Show a bank account"
        param :id, :number, desc: "Bank account ID", required: true
        def show
          account = current_user.bank_accounts
            .left_joins(:bank_transactions)
            .select("bank_accounts.*, COUNT(bank_transactions.id) AS transactions_count")
            .group("bank_accounts.id")
            .find(params[:id])

          render json: {
            data: serialize_bank_account(account),
            meta: {}
          }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        api :POST, "/banking/bank_accounts", "Create a bank account"
        param :bank_account, Hash, desc: "Bank account attributes", required: true do
          param :name, String, desc: "Account name", required: true
          param :account_type, String, desc: "Account type (checking, savings, credit_card, investment, other)", required: false
          param :active, :boolean, desc: "Whether account is active", required: false
          param :letter, String, desc: "Display letter", required: false
          param :bg_color, String, desc: "Background color (hex)", required: false
          param :fg_color, String, desc: "Foreground color (hex)", required: false
        end
        def create
          account = current_user.bank_accounts.build(bank_account_params)

          if account.save
            render json: {
              data: serialize_bank_account(account),
              meta: {}
            }, status: :created
          else
            render_error(
              account.errors.full_messages.join(", "),
              status: :unprocessable_entity,
              errors: account.errors.full_messages
            )
          end
        end

        api :PATCH, "/banking/bank_accounts/:id", "Update a bank account"
        param :id, :number, desc: "Bank account ID", required: true
        param :bank_account, Hash, desc: "Bank account attributes", required: true do
          param :name, String, desc: "Account name", required: false
          param :account_type, String, desc: "Account type", required: false
          param :active, :boolean, desc: "Whether account is active", required: false
          param :letter, String, desc: "Display letter", required: false
          param :bg_color, String, desc: "Background color (hex)", required: false
          param :fg_color, String, desc: "Foreground color (hex)", required: false
        end
        def update
          account = current_user.bank_accounts.find(params[:id])

          if account.update(bank_account_params)
            render json: {
              data: serialize_bank_account(account),
              meta: {}
            }, status: :ok
          else
            render_error(
              account.errors.full_messages.join(", "),
              status: :unprocessable_entity,
              errors: account.errors.full_messages
            )
          end
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        api :DELETE, "/banking/bank_accounts/:id", "Delete a bank account"
        description "Deletes a bank account. Associated transactions will have their bank_account_id set to null."
        param :id, :number, desc: "Bank account ID", required: true
        def destroy
          account = current_user.bank_accounts.find(params[:id])
          account.destroy!

          render json: { data: nil, meta: {} }, status: :ok
        rescue ActiveRecord::RecordNotFound
          render_not_found
        end

        private

        def authorize_banking_access!
          authorize_feature!(:banking)
        end

        def bank_account_params
          params.require(:bank_account).permit(:name, :account_type, :active, :letter, :bg_color, :fg_color)
        end

        def serialize_bank_account(account)
          {
            id: account.id,
            name: account.name,
            account_type: account.account_type,
            active: account.active,
            letter: account.respond_to?(:display_letter) ? account.display_letter : account.letter,
            bg_color: account.bg_color,
            fg_color: account.fg_color,
            transactions_count: account.respond_to?(:transactions_count) ? account.transactions_count : nil,
            created_at: account.created_at.iso8601,
            updated_at: account.updated_at.iso8601
          }
        end
      end
    end
  end
end
