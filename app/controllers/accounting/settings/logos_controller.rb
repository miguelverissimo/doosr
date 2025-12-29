module Accounting
  module Settings
    class LogosController < ApplicationController
      before_action :authenticate_user!
      before_action :set_accounting_logo, only: [:update, :destroy]

      def index
        render ::Views::Accounting::Settings::Logos::ListContents.new(user: current_user)
      end

      def create
        @accounting_logo = current_user.accounting_logos.new(accounting_logo_params)

        respond_to do |format|
          if @accounting_logo.save
            format.turbo_stream do
              render turbo_stream: [
                turbo_stream.update("accounting_logos_content", ::Views::Accounting::Settings::Logos::ListContents.new(user: current_user)),
                turbo_stream.append("body", "<script>window.toast && window.toast('Logo created successfully', { type: 'success' });</script>")
              ]
            end
            format.html { redirect_to accounting_index_path, notice: "Logo created successfully." }
          else
            format.turbo_stream do
              error_message = @accounting_logo.errors.full_messages.join(', ')
              render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Failed to create logo: #{error_message}', { type: 'error' });</script>")
            end
            format.html { redirect_to accounting_index_path, alert: "Failed to create logo" }
          end
        end
      end

      def update
        respond_to do |format|
          if @accounting_logo.update(accounting_logo_params)
            format.turbo_stream do
              render turbo_stream: [
                turbo_stream.replace("accounting_logo_#{@accounting_logo.id}_div", ::Views::Accounting::Settings::Logos::LogoRow.new(accounting_logo: @accounting_logo)),
                turbo_stream.append("body", "<script>window.toast && window.toast('Logo updated successfully', { type: 'success' });</script>")
              ]
            end
            format.html { redirect_to accounting_index_path, notice: "Logo updated successfully." }
          else
            format.turbo_stream do
              error_message = @accounting_logo.errors.full_messages.join(', ')
              render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Failed to update logo: #{error_message}', { type: 'error' });</script>")
            end
            format.html { redirect_to accounting_index_path, alert: "Failed to update logo" }
          end
        end
      end

      def destroy
        @accounting_logo.destroy

        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.update("accounting_logos_content", ::Views::Accounting::Settings::Logos::ListContents.new(user: current_user)),
              turbo_stream.append("body", "<script>window.toast && window.toast('Logo deleted successfully', { type: 'success' });</script>")
            ]
          end
          format.html { redirect_to accounting_index_path, notice: "Logo deleted successfully." }
        end
      end

      private

      def set_accounting_logo
        @accounting_logo = current_user.accounting_logos.find(params[:id])
      end

      def accounting_logo_params
        params.require(:accounting_logo).permit(:title, :description, :image)
      end
    end
  end
end