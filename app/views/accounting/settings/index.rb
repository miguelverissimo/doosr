module Views
  module Accounting
    module Settings
      class Index < Views::Base
        def initialize
        end

        def view_template
          div(class: "flex h-full flex-col") do
            h1(class: "text-xl font-bold") { "Settings" }
            div(class: "rounded-lg border p-6 space-y-4 bg-background text-foreground mt-4") do
              render RubyUI::Dialog.new do
                div(class: "flex justify-end") do
                  render RubyUI::DialogTrigger.new do
                    Button(variant: :primary, size: :sm) { "Add Tax Bracket" }
                  end
                end
              render Views::Accounting::Settings::TaxBrackets::List.new(user: view_context.current_user)
                
                render_tax_bracket_form_dialog
              end
            end
          end
        end

        def render_tax_bracket_form_dialog(tax_bracket: nil)
          render RubyUI::DialogContent.new(size: :lg) do
            render RubyUI::DialogHeader.new do
              render RubyUI::DialogTitle.new { "Tax Brackets" }
              render RubyUI::DialogDescription.new { "Manage tax bracket" }
            end

            render RubyUI::DialogMiddle.new do
              render Components::Accounting::Settings::TaxBrackets::Form.new(tax_bracket: tax_bracket)
            end
          end
        end
      end
    end
  end
end