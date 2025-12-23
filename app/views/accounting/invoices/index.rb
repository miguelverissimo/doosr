module Views
  module Accounting
    module Invoices
      class Index < Views::Base
        def initialize
        end

        def view_template
          div(class: "flex h-full flex-col") do
            tabs_data = [
              {value: "invoices", label: "Invoices"},
              {value: "templates", label: "Templates"},
            ]
            Tabs(default_value: "invoices") do
              render RubyUI::ResponsiveTabsList.new(
                tabs: tabs_data,
                current_value: "invoices"
              )
              TabsContent(value: "invoices") do
                div(class: "rounded-lg border p-6 space-y-4 bg-background text-foreground") do
                  render Views::Accounting::Invoices::List.new(user: view_context.current_user)
                end
              end
              TabsContent(value: "templates") do
                div(class: "rounded-lg border p-6 space-y-4 bg-background text-foreground") do
                  render RubyUI::Dialog.new do
                    div(class: "flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 mb-2") do
                      render RubyUI::DialogTitle.new { "Your Invoice Templates" }
                      render RubyUI::DialogTrigger.new do
                        Button(variant: :primary, size: :sm, class: "w-full sm:w-auto") { "Add Invoice Template" }
                      end
                    end
                    render Views::Accounting::Invoices::Templates::List.new(user: view_context.current_user)
                    render_invoice_template_form_dialog
                  end
                end
              end
            end
          end
        end

        def render_invoice_template_form_dialog(invoice_template: nil)
          render RubyUI::DialogContent.new(size: :lg) do
            render RubyUI::DialogHeader.new do
              render RubyUI::DialogDescription.new { "Manage invoice template" }
            end

            render RubyUI::DialogMiddle.new do
              render Components::Accounting::Invoices::Templates::Form.new(invoice_template: invoice_template, user: view_context.current_user)
            end
          end
        end
      end
    end
  end
end