module Views
  module Checklists
    class Index < ::Views::Base
      def initialize(checklist_templates:)
        @checklist_templates = checklist_templates
      end

      def view_template
        div(class: "flex h-full flex-col") do
          render RubyUI::Dialog.new do
            div(class: "flex items-center justify-between mb-2") do
              render RubyUI::DialogTitle.new { "Checklist templates" }
              render RubyUI::DialogTrigger.new do
                Button(variant: :primary, size: :sm) { "Add Checklist Template" }
              end
            end

            render ::Views::Checklists::List.new(user: view_context.current_user)
            render_checklist_template_form_dialog
          end
        end
      end

      def render_checklist_template_form_dialog(checklist_template: nil)
        render RubyUI::DialogContent.new(size: :lg) do
          render RubyUI::DialogHeader.new do
            render RubyUI::DialogDescription.new { "Manage checklist template" }
          end

          render RubyUI::DialogMiddle.new do
            render ::Components::Checklists::Form.new(checklist_template: checklist_template)
          end
        end
      end
    end
  end
end