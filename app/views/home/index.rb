# frozen_string_literal: true

class Views::Home::Index < Views::Base
  def view_template
    div(class: "vertical space-y-8") do
      # Page content goes here - matching @doos structure
      h1 { "Welcome to Doosr" }
      p { "This is the home page content." }
    end
  end
end
