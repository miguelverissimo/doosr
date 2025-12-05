# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  layout -> { Views::Layouts::AuthLayout.new }
  
  def new
    self.resource = resource_class.new
    render Views::Auth::SignUp.new(
      resource: resource,
      resource_name: resource_name,
      minimum_password_length: minimum_password_length
    )
  end
  
  private
  
  def minimum_password_length
    @minimum_password_length ||= resource_class.password_length.min
  end
end

