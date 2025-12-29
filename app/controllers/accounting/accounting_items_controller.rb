module Accounting
  class AccountingItemsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_accounting_item, only: [ :update, :destroy ]

    def index
      render ::Views::Accounting::AccountingItems::ListContent.new(user: current_user)
    end

    def create
      params_hash = accounting_item_params.to_h
      convert_price_to_cents(params_hash)
      @accounting_item = ::Accounting::AccountingItem.new(params_hash)
      @accounting_item.user = current_user

      respond_to do |format|
        if @accounting_item.save
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.update("accounting_items_content", ::Views::Accounting::AccountingItems::ListContent.new(user: current_user)),
              turbo_stream.append("body", "<script>window.toast && window.toast('Accounting item created successfully', { type: 'success' });</script>")
            ]
          end
          format.html { redirect_to accounting_index_path, notice: "Accounting item created successfully." }
        else
          format.turbo_stream do
            render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Failed to create accounting item', { type: 'error' });</script>")
          end
          format.html { redirect_to accounting_index_path, alert: "Failed to create accounting item" }
        end
      end
    end

    def update
      params_hash = accounting_item_params.to_h
      convert_price_to_cents(params_hash)
      if @accounting_item.update(params_hash)
        render turbo_stream: [
          turbo_stream.update(
            "accounting_items_content",
            ::Views::Accounting::AccountingItems::ListContent.new(user: current_user)
          ),
          turbo_stream.append(
            "body",
            "<script>window.toast && window.toast('Accounting item updated successfully', { type: 'success' });</script>"
          )
        ]
      else
        render turbo_stream: turbo_stream.append(
          "body",
          "<script>window.toast && window.toast('Failed to update accounting item', { type: 'error' });</script>"
        )
      end
    end

    def destroy
      @accounting_item.destroy

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("accounting_items_content", ::Views::Accounting::AccountingItems::ListContent.new(user: current_user)),
            turbo_stream.append("body", "<script>window.toast && window.toast('Accounting item deleted successfully', { type: 'success' });</script>")
          ]
        end
        format.html { redirect_to accounting_index_path, notice: "Accounting item deleted successfully." }
      end
    end

    private

    def set_accounting_item
      @accounting_item = ::Accounting::AccountingItem.where(user: current_user).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to accounting_index_path, alert: "Accounting item not found"
    end

    def accounting_item_params
      params.require(:accounting_item).permit(:reference, :name, :kind, :description, :unit, :price, :currency, :convert_currency, :detail)
    end

    def convert_price_to_cents(params_hash)
      # Convert price from decimal to cents
      if params_hash[:price].present?
        params_hash[:price] = (params_hash[:price].to_f * 100).round
      end
    end
  end
end
