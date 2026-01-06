module Accounting
  class CustomersController < ApplicationController
    before_action :authenticate_user!
    before_action :set_customer, only: [ :update, :destroy ]

    def index
      render ::Views::Accounting::Customers::ListContent.new(user: current_user)
    end

    def create
      @customer = ::Accounting::Customer.new(customer_params)
      @customer.user = current_user

      # Create address from address params
      if params[:address].present?
        address_params = params.require(:address).permit(:name, :full_address, :country, :fiscal_number)
        address = ::Address.new(address_params.except(:fiscal_number))
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
            handle_fiscal_info(address, params[:address][:fiscal_number], @customer.name)

            format.turbo_stream do
              render turbo_stream: [
                turbo_stream.update("customers_list", ::Views::Accounting::Customers::ListContent.new(user: current_user)),
                turbo_stream.append("body", "<script>window.toast && window.toast('Customer created successfully', { type: 'success' });</script>")
              ]
            end
            format.html { redirect_to accounting_index_path, notice: "Customer created successfully." }
          else
            address.destroy # Clean up address if customer save fails
            error_message = @customer.errors.full_messages.join(", ")
            format.turbo_stream do
              render turbo_stream: turbo_stream.append("body", "<script>window.toast && window.toast('Failed to create customer: #{error_message}', { type: 'error' });</script>")
            end
            format.html { redirect_to accounting_index_path, alert: "Failed to create customer" }
          end
        else
          error_message = address.errors.full_messages.join(", ")
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
        address_params = params.require(:address).permit(:name, :full_address, :country, :fiscal_number)
        address = @customer.address

        # Ensure address name matches customer name
        address_params[:name] = customer_params[:name] if customer_params[:name].present?

        address_saved = address.update(address_params.except(:fiscal_number))
      else
        address_saved = true
        address = @customer.address
      end

      if address_saved && @customer.update(customer_params)
        if address.present? && params[:address].present?
          handle_fiscal_info(address, params[:address][:fiscal_number], @customer.name)
        end

        render turbo_stream: [
          turbo_stream.update(
            "customers_list",
            ::Views::Accounting::Customers::ListContent.new(user: current_user)
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
            turbo_stream.update("customers_list", ::Views::Accounting::Customers::ListContent.new(user: current_user)),
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

    def handle_fiscal_info(address, fiscal_number, customer_name)
      if fiscal_number.present?
        fiscal_info = address.fiscal_info || address.build_fiscal_info
        fiscal_info.user = current_user
        fiscal_info.title = customer_name
        fiscal_info.kind = :customer
        fiscal_info.tax_number = fiscal_number
        fiscal_info.save
      elsif address.fiscal_info.present?
        # If fiscal_number is blank and fiscal_info exists, destroy it
        address.fiscal_info.destroy
      end
    end
  end
end
