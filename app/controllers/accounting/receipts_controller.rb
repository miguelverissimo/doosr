module Accounting
  class ReceiptsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_receipt, only: [:update, :destroy]

    def index
      render Views::Accounting::Receipts::Index.new
    end

    def create
      receipt_params_hash = receipt_params.to_h
      
      # Convert value to cents
      if receipt_params_hash[:value].present?
        receipt_params_hash[:value] = (receipt_params_hash[:value].to_f * 100).round
      end

      # Convert dates to datetime
      if receipt_params_hash[:issue_date].present?
        receipt_params_hash[:issue_date] = DateTime.parse(receipt_params_hash[:issue_date])
      end
      if receipt_params_hash[:payment_date].present?
        receipt_params_hash[:payment_date] = DateTime.parse(receipt_params_hash[:payment_date])
      end

      @receipt = ::Accounting::Receipt.new(receipt_params_hash)
      @receipt.user = current_user

      if @receipt.save
        # Create items from calculator values
        if params[:receipt][:items_attributes].present?
          params[:receipt][:items_attributes].each do |_index, item_params|
            receipt_item = current_user.receipt_items.find_by(id: item_params[:receipt_item_id])
            next unless receipt_item

            quantity = item_params[:quantity].to_i
            value_with_tax = item_params[:value_with_tax].to_i

            # Calculate gross_value from value_with_tax and tax percentage
            tax_percentage = receipt_item.tax_bracket.percentage || 0
            gross_value = if tax_percentage > 0
              (value_with_tax / (1 + tax_percentage / 100.0)).round
            else
              value_with_tax
            end

            @receipt.items.create!(
              user: current_user,
              receipt_item: receipt_item,
              quantity: quantity.to_s,
              gross_value: gross_value,
              tax_percentage: tax_percentage,
              value_with_tax: value_with_tax
            )
          end
        end

        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.update(
                "receipts_list",
                render_to_string(Views::Accounting::Receipts::ListContent.new(user: current_user))
              ),
              turbo_stream.append(
                "body",
                "<script>(function() { if (window.toast) { window.toast('Receipt created successfully', { type: 'success' }); } })();</script>"
              )
            ]
          end
          format.html { redirect_to accounting_index_path, notice: "Receipt created successfully." }
        end
      else
        error_message = @receipt.errors.full_messages.join(', ')
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.append(
              "body",
              "<script>(function() { if (window.toast) { window.toast('Failed to create receipt: #{error_message}', { type: 'error' }); } })();</script>"
            )
          end
          format.html { redirect_to accounting_index_path, alert: "Failed to create receipt" }
        end
      end
    end

    def update
      receipt_params_hash = receipt_params.to_h
      
      # Convert value to cents
      if receipt_params_hash[:value].present?
        receipt_params_hash[:value] = (receipt_params_hash[:value].to_f * 100).round
      end

      # Convert dates to datetime
      if receipt_params_hash[:issue_date].present?
        receipt_params_hash[:issue_date] = DateTime.parse(receipt_params_hash[:issue_date])
      end
      if receipt_params_hash[:payment_date].present?
        receipt_params_hash[:payment_date] = DateTime.parse(receipt_params_hash[:payment_date])
      end

      if @receipt.update(receipt_params_hash)
        # Update items
        if params[:receipt][:items_attributes].present?
          @receipt.items.destroy_all
          
          params[:receipt][:items_attributes].each do |_index, item_params|
            receipt_item = current_user.receipt_items.find_by(id: item_params[:receipt_item_id])
            next unless receipt_item

            quantity = item_params[:quantity].to_f
            value_with_tax = item_params[:value_with_tax].to_i

            # Calculate gross_value from value_with_tax and tax percentage
            tax_percentage = receipt_item.tax_bracket.percentage || 0
            gross_value = if tax_percentage > 0
              (value_with_tax / (1 + tax_percentage / 100.0)).round
            else
              value_with_tax
            end

            @receipt.items.create!(
              user: current_user,
              receipt_item: receipt_item,
              quantity: quantity.to_s,
              gross_value: gross_value,
              tax_percentage: tax_percentage,
              value_with_tax: value_with_tax
            )
          end
        end

        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.update(
                "receipts_list",
                render_to_string(Views::Accounting::Receipts::ListContent.new(user: current_user))
              ),
              turbo_stream.append(
                "body",
                "<script>(function() { if (window.toast) { window.toast('Receipt updated successfully', { type: 'success' }); } })();</script>"
              )
            ]
          end
          format.html { redirect_to accounting_index_path, notice: "Receipt updated successfully." }
        end
      else
        error_message = @receipt.errors.full_messages.join(', ')
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.append(
              "body",
              "<script>(function() { if (window.toast) { window.toast('Failed to update receipt: #{error_message}', { type: 'error' }); } })();</script>"
            )
          end
          format.html { redirect_to accounting_index_path, alert: "Failed to update receipt" }
        end
      end
    end

    def destroy
    end

    private

    def set_receipt
      @receipt = current_user.receipts.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to accounting_index_path, alert: "Receipt not found"
    end

    def receipt_params
      params.require(:receipt).permit(:reference, :kind, :issue_date, :payment_date, :value, :invoice_id)
    end
  end
end

