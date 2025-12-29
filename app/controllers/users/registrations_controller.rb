# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  layout -> { ::Views::Layouts::AuthLayout.new }

  def new
    self.resource = resource_class.new
    render ::Views::Auth::SignUp.new(
      resource: resource,
      resource_name: resource_name,
      minimum_password_length: minimum_password_length
    )
  end

  def create
    build_resource(sign_up_params)

    resource.save
    yield resource if block_given?

    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      # Validation failed - show errors
      clean_up_passwords resource
      set_minimum_password_length

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update(
            "auth_error",
            partial: "users/registrations/errors",
            locals: { resource: resource }
          ), status: :unprocessable_entity
        end

        format.html do
          render ::Views::Auth::SignUp.new(
            resource: resource,
            resource_name: resource_name,
            minimum_password_length: minimum_password_length
          ), status: :unprocessable_entity
        end
      end
    end
  end

  private

  def sign_up_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def minimum_password_length
    @minimum_password_length ||= resource_class.password_length.min
  end
end
