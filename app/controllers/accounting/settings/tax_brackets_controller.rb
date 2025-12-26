module Accounting
  module Settings
    class TaxBracketsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_tax_bracket, only: [:update, :destroy]

      def create
        @tax_bracket = ::Accounting::TaxBracket.new(tax_bracket_params)
        @tax_bracket.user = current_user

        respond_to do |format|
          if @tax_bracket.save
            format.turbo_stream do
              render turbo_stream: turbo_stream.update(
                "tax_brackets_list",
                Views::Accounting::Settings::TaxBrackets::ListContent.new(user: current_user)
              )
            end
            format.html { redirect_to accounting_index_path, notice: "Tax bracket created successfully." }
          else
            # For now, just redirect back with an error for HTML and Turbo requests
            message = "Failed to create tax bracket: #{@tax_bracket.errors.full_messages.join(', ')}"
            format.turbo_stream do
              flash.now[:alert] = message
              render turbo_stream: turbo_stream.append(
                "body",
                "<script>window.toast && window.toast(#{message.to_json}, { type: 'error' })</script>"
              )
            end
            format.html { redirect_to accounting_index_path, alert: message }
          end
        end
      end

      def update
        respond_to do |format|
          if @tax_bracket.update(tax_bracket_params)
            format.turbo_stream do
              render turbo_stream: turbo_stream.update(
                "tax_brackets_list",
                Views::Accounting::Settings::TaxBrackets::ListContent.new(user: current_user)
              )
            end
            format.html { redirect_to accounting_index_path, notice: "Tax bracket updated successfully." }
          else
            message = "Failed to update tax bracket: #{@tax_bracket.errors.full_messages.join(', ')}"
            format.turbo_stream do
              flash.now[:alert] = message
              render turbo_stream: turbo_stream.append(
                "body",
                "<script>window.toast && window.toast(#{message.to_json}, { type: 'error' })</script>"
              )
            end
            format.html { redirect_to accounting_index_path, alert: message }
          end
        end
      end

      def destroy
        if @tax_bracket.destroy
          respond_to do |format|
            format.turbo_stream do
              render turbo_stream: [
                turbo_stream.append("body", "<div data-controller='auto-exec' data-auto-exec-code-value=\"document.querySelector('[data-state=\\\"open\\\"][role=\\\"alertdialog\\\"]')?.querySelector('[data-radix-collection-item]')?.click();\"></div>"),
                turbo_stream.update("tax_brackets_list", Views::Accounting::Settings::TaxBrackets::ListContent.new(user: current_user))
              ]
            end
            format.html { redirect_to accounting_index_path, notice: "Tax bracket deleted successfully." }
          end
        else
          message = "Cannot delete tax bracket: it is still being used by invoices or receipt items"

          respond_to do |format|
            format.turbo_stream do
              response.headers["X-Error-Message"] = message
              head :ok
            end
            format.html { redirect_to accounting_index_path, alert: message }
          end
        end
      end

      private

      def set_tax_bracket
        @tax_bracket = current_user.tax_brackets.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.append(
              "body",
              "<script>window.toast && window.toast('Tax bracket not found', { type: 'error' })</script>"
            )
          end
          format.html { redirect_to accounting_index_path, alert: "Tax bracket not found" }
        end
      end

      def tax_bracket_params
        params.require(:tax_bracket).permit(:name, :percentage, :legal_reference)
      end
    end
  end
end

