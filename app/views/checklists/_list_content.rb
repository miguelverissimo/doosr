module Views
  module Checklists
    class ListContent < ::Views::Base
      def initialize(user:, **attrs)
        @user = user
        @checklists = ::Checklist.template.where(user: @user)
        super(**attrs)
      end

      def view_template
        if @checklists.empty?
          div(class: "flex h-full flex-col items-center justify-center") do
            p(class: "text-sm text-gray-500") { "No checklist templates found" }
          end
        else
          @checklists.each do |checklist|
            div(id: "checklist_#{checklist.id}_div", class: "mt-2") do
              render ::Views::Checklists::TemplateRow.new(checklist: checklist)
            end
          end
        end
      end
    end
  end
end