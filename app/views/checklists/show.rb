# frozen_string_literal: true

module Views
  module Checklists
    class Show < ::Views::Base
      def initialize(checklist:)
        @checklist = checklist
      end

      def view_template
        div(class: "flex h-full flex-col") do
          # Back button and description
          if @checklist.description.present?
            div(class: "mb-6") do
              p(class: "text-muted-foreground text-sm") { @checklist.description }
            end
          end

          # Content area (replaceable)
          render ::Views::Checklists::Content.new(checklist: @checklist)
        end
      end
    end
  end
end
