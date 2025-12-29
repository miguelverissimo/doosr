# frozen_string_literal: true

class ::Components::Base < Phlex::HTML
  include RubyUI
  # Include any helpers you want to be available across all components
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::TurboFrameTag

  attr_reader :attrs

  def initialize(**user_attrs)
    @attrs = user_attrs || {}
    super
  end

  # CSRF helper usable inside Phlex components (e.g. Forms built with RubyUI::Form)
  def csrf_token_field
    token = view_context.form_authenticity_token
    input type: "hidden", name: "authenticity_token", value: token
  end


  if Rails.env.development?
    def before_template
      comment { "Before #{self.class.name}" }
      super
    end
  end
end
