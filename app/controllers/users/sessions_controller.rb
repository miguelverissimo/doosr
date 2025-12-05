# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  layout -> { Views::Layouts::AuthLayout.new }
  
  def new
    render Views::Auth::SignIn.new(
      resource: resource,
      resource_name: resource_name,
      devise_mapping: devise_mapping
    )
  end
end
