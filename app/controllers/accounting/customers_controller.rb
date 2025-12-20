module Accounting
  class CustomersController < ApplicationController
    before_action :authenticate_user!
    before_action :set_customer, only: [:update, :destroy]

    def index
      @customers = ::Accounting::Customer.where(user: current_user)
    end

    def create
      @customer = ::Accounting::Customer.new(customer_params)
      @customer.user = current_user

      # Create address from address params
      if params[:address].present?
        address_params = params.require(:address).permit(:name, :full_address, :country)
        address = ::Address.new(address_params)
        address.user = current_user
        address.address_type = :customer
        address.state = :active
        # Ensure address name matches customer name
        address.name = customer_params[:name] if customer_params[:name].present?
      else
        address = nil
      end

      respond_to do |format|
        if address.nil?
          format.turbo_stream do
            render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Address information is required', { type: 'error' });</script>")
          end
          format.html { redirect_to accounting_index_path, alert: "Address information is required" }
        elsif address.save
          @customer.address = address
          if @customer.save
            format.turbo_stream do
              render turbo_stream: [
                turbo_stream.update("customers_list", Views::Accounting::Customers::ListContent.new(user: current_user)),
                turbo_stream.append("body", "<script>window.toast && window.toast('Customer created successfully', { type: 'success' });</script>")
              ]
            end
            format.html { redirect_to accounting_index_path, notice: "Customer created successfully." }
          else
            address.destroy # Clean up address if customer save fails
            error_message = @customer.errors.full_messages.join(', ')
            format.turbo_stream do
              render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Failed to create customer: #{error_message}', { type: 'error' });</script>")
            end
            format.html { redirect_to accounting_index_path, alert: "Failed to create customer" }
          end
        else
          error_message = address.errors.full_messages.join(', ')
          format.turbo_stream do
            render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Failed to create address: #{error_message}', { type: 'error' });</script>")
          end
          format.html { redirect_to accounting_index_path, alert: "Failed to create address" }
        end
      end
    end

    def update
      # Update address from address params
      if params[:address].present?
        address_params = params.require(:address).permit(:name, :full_address, :country)
        address = @customer.address
        
        # Ensure address name matches customer name
        address_params[:name] = customer_params[:name] if customer_params[:name].present?

        address_saved = address.update(address_params)
      else
        address_saved = true
      end

      if address_saved && @customer.update(customer_params)
        render turbo_stream: [
          turbo_stream.update(
            "customers_list",
            Views::Accounting::Customers::ListContent.new(user: current_user)
          ),
          turbo_stream.append(
            "body",
            "<script>window.toast && window.toast('Customer updated successfully', { type: 'success' });</script>"
          )
        ]
      else
        render turbo_stream: turbo_stream.append(
          "body",
          "<script>window.toast && window.toast('Failed to update customer', { type: 'error' });</script>"
        )
      end
    end

    def destroy
      @customer.destroy

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("customers_list", Views::Accounting::Customers::ListContent.new(user: current_user)),
            turbo_stream.append("body", "<script>window.toast && window.toast('Customer deleted successfully', { type: 'success' });</script>")
          ]
        end
        format.html { redirect_to accounting_index_path, notice: "Customer deleted successfully." }
      end
    end

    private

    def set_customer
      @customer = ::Accounting::Customer.where(user: current_user).find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to accounting_index_path, alert: "Customer not found"
    end

    def customer_params
      params.require(:customer).permit(:name, :telephone, :contact_name, :contact_email, :contact_phone, :billing_contact_name, :billing_email, :billing_phone, :notes)
    end
  end
end