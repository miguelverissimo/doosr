# frozen_string_literal: true

module Views
  module Lists
    class New < Views::Base
      def initialize(list:)
        @list = list
      end

      def view_template
        div(class: "flex h-full flex-col") do
          # Header
          div(class: "mb-6") do
            h1(class: "text-2xl font-bold") { "New List" }
          end

          # Form
          div(class: "max-w-2xl") do
            render Form.new(list: @list, action: lists_path)
          end
        end
      end
    end
  end
end
