# frozen_string_literal: true

class ApplicationDeviseController < ActionController::Base
  layout -> { ::Views::Layouts::AuthLayout.new }
end
