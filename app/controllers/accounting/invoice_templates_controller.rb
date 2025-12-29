module Accounting
  class InvoiceTemplatesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_invoice_template, only: [ :update, :destroy ]

    def index
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "invoice_templates_content",
            ::Views::Accounting::Invoices::Templates::ListContent.new(user: current_user)
          )
        end
        format.html do
          render ::Views::Accounting::Invoices::Templates::ListContent.new(user: current_user)
        end
      end
    end

    def create
      # Split out nested invoice_template_items_attributes so we don't assign them
      # directly (we build invoice_template_items manually below).
      raw_params = invoice_template_params
      template_item_params = raw_params.delete(:invoice_template_items_attributes)

      @invoice_template = current_user.invoice_templates.new(raw_params)

      # Build invoice template items from nested attributes
      if template_item_params.present?
        template_item_params.each do |_index, item_params|
          next if item_params[:_destroy] == "1" || item_params[:item_id].blank?

          accounting_item = current_user.accounting_items.find_by(id: item_params[:item_id])
          tax_bracket = current_user.tax_brackets.find_by(id: item_params[:tax_bracket_id])

          next unless accounting_item && tax_bracket

          @invoice_template.invoice_template_items.build(
            user: current_user,
            item: accounting_item,
            tax_bracket: tax_bracket,
            description: item_params[:description],
            quantity: item_params[:quantity],
            unit: item_params[:unit] || accounting_item.unit,
            discount_rate: item_params[:discount_rate] || 0
          )
        end
      end

      respond_to do |format|
        if @invoice_template.save
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace("invoice_templates_content", ::Views::Accounting::Invoices::Templates::ListContent.new(user: current_user)),
              turbo_stream.append("body", "<script>window.toast && window.toast('Invoice template created successfully', { type: 'success' });</script>")
            ]
          end
          format.html { redirect_to accounting_index_path, notice: "Invoice template created successfully." }
        else
          format.turbo_stream do
            error_message = @invoice_template.errors.full_messages.join(", ")
            render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Failed to create invoice template: #{error_message}', { type: 'error' });</script>")
          end
          format.html { redirect_to accounting_index_path, alert: "Failed to create invoice template" }
        end
      end
    end

    def update
      # Split out nested invoice_template_items_attributes
      raw_params = invoice_template_params
      template_item_params = raw_params.delete(:invoice_template_items_attributes)

      success = false

      ActiveRecord::Base.transaction do
        unless @invoice_template.update(raw_params)
          raise ActiveRecord::Rollback
        end

        if template_item_params.present?
          # Replace all template items with the submitted ones
          @invoice_template.invoice_template_items.destroy_all

          template_item_params.each do |_index, item_params|
            next if item_params[:_destroy] == "1" || item_params[:item_id].blank?

            accounting_item = current_user.accounting_items.find_by(id: item_params[:item_id])
            tax_bracket = current_user.tax_brackets.find_by(id: item_params[:tax_bracket_id])

            next unless accounting_item && tax_bracket

            @invoice_template.invoice_template_items.build(
              user: current_user,
              item: accounting_item,
              tax_bracket: tax_bracket,
              description: item_params[:description],
              quantity: item_params[:quantity],
              unit: item_params[:unit] || accounting_item.unit,
              discount_rate: item_params[:discount_rate] || 0
            )
          end

          unless @invoice_template.save
            raise ActiveRecord::Rollback
          end
        end

        success = true
      end

      respond_to do |format|
        if success
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace("invoice_template_#{@invoice_template.id}_div", ::Views::Accounting::Invoices::Templates::InvoiceTemplateRow.new(invoice_template: @invoice_template)),
              turbo_stream.append("body", "<script>window.toast && window.toast('Invoice template updated successfully', { type: 'success' });</script>")
            ]
          end
          format.html { redirect_to accounting_index_path, notice: "Invoice template updated successfully." }
        else
          format.turbo_stream do
            error_message = @invoice_template.errors.full_messages.join(", ")
            render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Failed to update invoice template: #{error_message}', { type: 'error' });</script>")
          end
          format.html { redirect_to accounting_index_path, alert: "Failed to update invoice template" }
        end
      end
    end

    def destroy
      @invoice_template.destroy

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("invoice_templates_content", ::Views::Accounting::Invoices::Templates::ListContent.new(user: current_user)),
            turbo_stream.append("body", "<script>window.toast && window.toast('Invoice template deleted successfully', { type: 'success' });</script>")
          ]
        end
        format.html { redirect_to accounting_index_path, notice: "Invoice template deleted successfully." }
      end
    end

    private

    def set_invoice_template
      @invoice_template = current_user.invoice_templates.includes(:invoice_template_items).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to accounting_index_path, alert: "Invoice template not found"
    end

    def invoice_template_params
      params.require(:invoice_template).permit(
        :name,
        :description,
        :accounting_logo_id,
        :provider_address_id,
        :customer_id,
        :currency,
        :bank_info_id,
        invoice_template_items_attributes: [
          :item_id,
          :quantity,
          :discount_rate,
          :tax_bracket_id,
          :description,
          :unit,
          :_destroy
        ]
      )
    end
  end
end
