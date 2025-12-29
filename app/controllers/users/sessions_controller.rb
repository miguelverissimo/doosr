# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  layout -> { ::Views::Layouts::AuthLayout.new }

  def new
    self.resource = resource_class.new(sign_in_params)
    render ::Views::Auth::SignIn.new(
      resource: resource,
      resource_name: resource_name,
      devise_mapping: devise_mapping
    )
  end

  def create
    self.resource = warden.authenticate!(auth_options)
    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, resource)
    yield resource if block_given?

    # Redirect to the authenticated root
    redirect_to after_sign_in_path_for(resource), status: :see_other
  rescue Warden::NotAuthenticated, StandardError => e
    # Authentication failed - catch all errors
    self.resource = resource_class.new(sign_in_params)
    error_message = "Invalid email or password."

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "auth_error",
          partial: "users/sessions/error",
          locals: { message: error_message }
        ), status: :unprocessable_entity
      end

      format.html do
        flash.now[:alert] = error_message
        render ::Views::Auth::SignIn.new(
          resource: resource,
          resource_name: resource_name,
          devise_mapping: devise_mapping
        ), status: :unprocessable_entity
      end
    end
  end
end
