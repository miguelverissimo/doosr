module Accounting
  module Settings
    class AddressesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_address, only: [:update, :destroy, :activate]

      def index
        render ::Views::Accounting::Settings::UserAddresses::ListContent.new(user: current_user)
      end

      def create
        @address = ::Address.new(address_params.except(:fiscal_number))
        @address.user = current_user
        @address.address_type = :user

        respond_to do |format|
          if @address.save
            handle_fiscal_info(@address, address_params[:fiscal_number])
            
            format.turbo_stream do
              render turbo_stream: [
                turbo_stream.update("addresses_content", ::Views::Accounting::Settings::UserAddresses::ListContent.new(user: current_user)),
                turbo_stream.append("body", "<script>window.toast && window.toast('Address created successfully', { type: 'success' });</script>")
              ]
            end
            format.html { redirect_to accounting_index_path, notice: "Address created successfully." }
          else
            format.turbo_stream do
              render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Failed to create address', { type: 'error' });</script>")
            end
            format.html { redirect_to accounting_index_path, alert: "Failed to create address" }
          end
        end
      end

      def update
        if @address.update(address_params.except(:fiscal_number))
          handle_fiscal_info(@address, address_params[:fiscal_number])
          
          render turbo_stream: [
            turbo_stream.update(
              "addresses_content",
              ::Views::Accounting::Settings::UserAddresses::ListContent.new(user: current_user)
            ),
            turbo_stream.append(
              "body",
              "<script>window.toast && window.toast('Address updated successfully', { type: 'success' });</script>"
            )
          ]
        else
          render turbo_stream: turbo_stream.append(
            "body",
            "<script>window.toast && window.toast('Failed to update address', { type: 'error' });</script>"
          )
        end
      end

      def activate
        new_state = @address.active? ? :inactive : :active
        respond_to do |format|
          if @address.update(state: new_state)
            message = new_state == :active ? "Address activated successfully" : "Address deactivated successfully"
            format.turbo_stream do
              render turbo_stream: [
                turbo_stream.update("addresses_content", ::Views::Accounting::Settings::UserAddresses::ListContent.new(user: current_user)),
                turbo_stream.append("body", "<script>window.toast && window.toast('#{message}', { type: 'success' });</script>")
              ]
            end
            format.html { redirect_to accounting_index_path, notice: message }
          else
            format.turbo_stream do
              render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Failed to update address state', { type: 'error' });</script>")
            end
            format.html { redirect_to accounting_index_path, alert: "Failed to update address state" }
          end
        end
      end

      def destroy
        @address.destroy

        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: [
              turbo_stream.update("addresses_content", ::Views::Accounting::Settings::UserAddresses::ListContent.new(user: current_user)),
              turbo_stream.append("body", "<script>window.toast && window.toast('Address deleted successfully', { type: 'success' });</script>")
            ]
          end
          format.html { redirect_to accounting_index_path, notice: "Address deleted successfully." }
        end
      end

      private

      def set_address
        @address = ::Address.where(user: current_user, address_type: :user).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to accounting_index_path, alert: "Address not found"
      end

      def address_params
        params.require(:address).permit(:name, :full_address, :country, :address_type, :state, :fiscal_number)
      end

      def handle_fiscal_info(address, fiscal_number)
        if fiscal_number.present?
          fiscal_info = address.fiscal_info || address.build_fiscal_info
          fiscal_info.user = current_user
          fiscal_info.title = address.name
          fiscal_info.kind = :provider
          fiscal_info.tax_number = fiscal_number
          fiscal_info.save
        elsif address.fiscal_info.present?
          # If fiscal_number is blank and fiscal_info exists, destroy it
          address.fiscal_info.destroy
        end
      end
    end
  end
end