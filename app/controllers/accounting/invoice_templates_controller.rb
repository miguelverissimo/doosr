module Accounting
  class InvoiceTemplatesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_invoice_template, only: [:update, :destroy]

    def index
      @invoice_templates = current_user.invoice_templates
    end

    def create
      @invoice_template = current_user.invoice_templates.new(invoice_template_params)

      respond_to do |format|
        if @invoice_template.save
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.update("invoice_templates_list", Views::Accounting::Invoices::Templates::ListContent.new(user: current_user)),
              turbo_stream.append("body", "<script>window.toast && window.toast('Invoice template created successfully', { type: 'success' });</script>")
            ]
          end
          format.html { redirect_to accounting_index_path, notice: "Invoice template created successfully." }
        else
          format.turbo_stream do
            error_message = @invoice_template.errors.full_messages.join(', ')
            render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Failed to create invoice template: #{error_message}', { type: 'error' });</script>")
          end
          format.html { redirect_to accounting_index_path, alert: "Failed to create invoice template" }
        end
      end
    end

    def update
      respond_to do |format|
        if @invoice_template.update(invoice_template_params)
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.replace("invoice_template_#{@invoice_template.id}_div", Views::Accounting::Invoices::Templates::InvoiceTemplateRow.new(invoice_template: @invoice_template)),
              turbo_stream.append("body", "<script>window.toast && window.toast('Invoice template updated successfully', { type: 'success' });</script>")
            ]
          end
          format.html { redirect_to accounting_index_path, notice: "Invoice template updated successfully." }
        else
          format.turbo_stream do
            error_message = @invoice_template.errors.full_messages.join(', ')
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
            turbo_stream.update("invoice_templates_list", Views::Accounting::Invoices::Templates::ListContent.new(user: current_user)),
            turbo_stream.append("body", "<script>window.toast && window.toast('Invoice template deleted successfully', { type: 'success' });</script>")
          ]
        end
        format.html { redirect_to accounting_index_path, notice: "Invoice template deleted successfully." }
      end
    end

    private

    def set_invoice_template
      @invoice_template = current_user.invoice_templates.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to accounting_index_path, alert: "Invoice template not found"
    end

    def invoice_template_params
      params.require(:invoice_template).permit(:name, :description, :accounting_logo_id, :provider_address_id, :customer_id, :currency)
    end
  end
end