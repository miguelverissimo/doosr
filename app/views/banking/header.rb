# frozen_string_literal: true

module Views
  module Banking
    class Header < ::Views::Base
      def view_template
        div(class: "flex items-center gap-3 flex-1") do
          h1(class: "font-semibold text-base") { "Banking" }
        end
      end
    end
  end
end
