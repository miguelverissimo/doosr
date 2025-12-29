module Accounting
  module Settings
    class BankInfosController < ApplicationController
      before_action :authenticate_user!
      before_action :set_bank_info, only: [ :update, :destroy ]

      def index
        render ::Views::Accounting::Settings::BankInfos::ListContent.new(user: current_user)
      end

      def create
        @bank_info = current_user.bank_infos.new(bank_info_params)
        @bank_info.kind = :user

        respond_to do |format|
          if @bank_info.save
            format.turbo_stream do
              render turbo_stream: [
                turbo_stream.update("bank_infos_content", ::Views::Accounting::Settings::BankInfos::ListContent.new(user: current_user)),
                turbo_stream.append("body", "<script>window.toast && window.toast('Bank info created successfully', { type: 'success' });</script>")
              ]
            end
            format.html { redirect_to accounting_index_path, notice: "Bank info created successfully." }
          else
            error_message = @bank_info.errors.full_messages.join(", ")
            format.turbo_stream do
              render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Failed to create bank info: #{error_message}', { type: 'error' });</script>")
            end
            format.html { redirect_to accounting_index_path, alert: "Failed to create bank info" }
          end
        end
      end

      def update
        respond_to do |format|
          if @bank_info.update(bank_info_params)
            format.turbo_stream do
              render turbo_stream: [
                turbo_stream.replace("bank_info_#{@bank_info.id}_div", ::Views::Accounting::Settings::BankInfos::BankInfoRow.new(bank_info: @bank_info)),
                turbo_stream.append("body", "<script>window.toast && window.toast('Bank info updated successfully', { type: 'success' });</script>")
              ]
            end
            format.html { redirect_to accounting_index_path, notice: "Bank info updated successfully." }
          else
            error_message = @bank_info.errors.full_messages.join(", ")
            format.turbo_stream do
              render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Failed to update bank info: #{error_message}', { type: 'error' });</script>")
            end
            format.html { redirect_to accounting_index_path, alert: "Failed to update bank info" }
          end
        end
      end

      def destroy
        respond_to do |format|
          if @bank_info.destroy
            format.turbo_stream do
              render turbo_stream: [
                turbo_stream.update("bank_infos_content", ::Views::Accounting::Settings::BankInfos::ListContent.new(user: current_user)),
                turbo_stream.append("body", "<script>window.toast && window.toast('Bank info deleted successfully', { type: 'success' });</script>")
              ]
            end
            format.html { redirect_to accounting_index_path, notice: "Bank info deleted successfully." }
          else
            error_message = @bank_info.errors.full_messages.join(", ")
            format.turbo_stream do
              render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Failed to delete bank info: #{error_message}', { type: 'error' });</script>")
            end
            format.html { redirect_to accounting_index_path, alert: "Failed to delete bank info" }
          end
        end
      end

      private

      def set_bank_info
        @bank_info = current_user.bank_infos.find(params[:id])
      end

      def bank_info_params
        params.require(:bank_info).permit(:name, :account_number, :routing_number, :iban, :swift_bic)
      end
    end
  end
end
