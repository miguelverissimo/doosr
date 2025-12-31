module Views
  module Accounting
    module Invoices
      class Index < ::Views::Base
        def initialize
        end

        def view_template
          div(class: "flex h-full flex-col") do
            tabs_data = [
              { value: "invoices", label: "Invoices" },
              { value: "templates", label: "Templates" }
            ]
            Tabs(default_value: "invoices") do
              render RubyUI::ResponsiveTabsList.new(
                tabs: tabs_data,
                current_value: "invoices"
              )
              TabsContent(value: "invoices", data: { controller: "lazy-tab" }) do
                div(class: "rounded-lg border p-6 space-y-4 bg-background text-foreground") do
                  render ::Views::Accounting::Invoices::List.new(user: view_context.current_user)
                end
              end
              TabsContent(value: "templates", data: { controller: "lazy-tab" }) do
                div(class: "rounded-lg border p-6 space-y-4 bg-background text-foreground") do
                  # Turbo frame for lazy-loaded template dialog
                  turbo_frame_tag "invoice_template_dialog"

                  div(class: "flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 mb-2") do
                    h3(class: "text-lg font-semibold") { "Your Invoice Templates" }
                    a(
                      href: view_context.new_invoice_template_path,
                      data: { turbo_frame: "invoice_template_dialog" },
                      class: "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:size-4 [&_svg]:shrink-0 shadow bg-primary text-primary-foreground hover:bg-primary/90 h-9 px-4 py-2 w-full sm:w-auto"
                    ) { "Add Invoice Template" }
                  end
                  render ::Views::Accounting::Invoices::Templates::List.new(user: view_context.current_user)
                end
              end
            end
          end
        end
      end
    end
  end
end
