module Accounting
  module Receipts
    class ReceiptItemsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_receipt_item, only: [:update, :destroy]

      def index
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "receipt_items_content",
              ::Views::Accounting::Receipts::ReceiptItems::ListContent.new(user: current_user)
            )
          end
          format.html do
            render ::Views::Accounting::Receipts::ReceiptItems::ListContent.new(user: current_user)
          end
        end
      end

      def create
        params_hash = receipt_item_params.to_h
        convert_price_to_cents(params_hash)

        @receipt_item = ::Accounting::ReceiptItem.new(params_hash)
        @receipt_item.user = current_user

        respond_to do |format|
          if @receipt_item.save
            format.turbo_stream do
              render turbo_stream: [
                turbo_stream.replace("receipt_items_content", ::Views::Accounting::Receipts::ReceiptItems::ListContent.new(user: current_user)),
                turbo_stream.append("body", "<script>window.toast && window.toast('Receipt item created successfully', { type: 'success' });</script>")
              ]
            end
            format.html { redirect_to accounting_index_path, notice: "Receipt item created successfully." }
          else
            error_message = @receipt_item.errors.full_messages.join(', ')
            format.turbo_stream do
              render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Failed to create receipt item: #{error_message}', { type: 'error' });</script>")
            end
            format.html { redirect_to accounting_index_path, alert: "Failed to create receipt item" }
          end
        end
      end

      def update
        params_hash = receipt_item_params.to_h
        convert_price_to_cents(params_hash)

        if @receipt_item.update(params_hash)
          render turbo_stream: [
            turbo_stream.replace(
              "receipt_items_content",
              ::Views::Accounting::Receipts::ReceiptItems::ListContent.new(user: current_user)
            ),
            turbo_stream.append(
              "body",
              "<script>window.toast && window.toast('Receipt item updated successfully', { type: 'success' });</script>"
            )
          ]
        else
          error_message = @receipt_item.errors.full_messages.join(', ')
          render turbo_stream: turbo_stream.append(
            "body",
            "<script>window.toast && window.toast('Failed to update receipt item: #{error_message}', { type: 'error' });</script>"
          )
        end
      end

      def destroy
        @receipt_item.destroy

        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace("receipt_items_content", ::Views::Accounting::Receipts::ReceiptItems::ListContent.new(user: current_user)),
              turbo_stream.append("body", "<script>window.toast && window.toast('Receipt item deleted successfully', { type: 'success' });</script>")
            ]
          end
          format.html { redirect_to accounting_index_path, notice: "Receipt item deleted successfully." }
        end
      end

      private

      def set_receipt_item
        @receipt_item = ::Accounting::ReceiptItem.where(user: current_user).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to accounting_index_path, alert: "Receipt item not found"
      end

      def receipt_item_params
        params.require(:receipt_item).permit(:reference, :description, :unit, :gross_unit_price, :tax_bracket_id, :exemption_motive, :unit_price_with_tax, :active)
      end

      def convert_price_to_cents(params_hash)
        # Convert gross_unit_price from decimal to cents
        if params_hash[:gross_unit_price].present?
          params_hash[:gross_unit_price] = (params_hash[:gross_unit_price].to_f * 100).round
        end

        # Convert unit_price_with_tax from decimal to cents
        if params_hash[:unit_price_with_tax].present?
          params_hash[:unit_price_with_tax] = (params_hash[:unit_price_with_tax].to_f * 100).round
        end
      end
    end
  end
end

