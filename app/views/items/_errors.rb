# frozen_string_literal: true

module Views
  module Items
    class Errors < ::Views::Base
      def initialize(item:)
        @item = item
      end

      def view_template
        return unless @item.errors.any?

        div(class: "rounded-lg border border-destructive/50 bg-destructive/10 p-3 text-sm text-destructive") do
          ul(class: "list-disc list-inside space-y-1") do
            @item.errors.full_messages.each do |message|
              li { message }
            end
          end
        end
      end
    end
  end
end
