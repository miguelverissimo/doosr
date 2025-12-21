module Views
  module Accounting
    class Index < Views::Base
      def initialize
      end

      def view_template
        div(class: "flex h-full flex-col") do
          tabs_data = [
            {value: "invoices", label: "Invoices"},
            {value: "receipts", label: "Receipts"},
            {value: "customers", label: "Customers"},
            {value: "items", label: "Items"},
            {value: "automations", label: "Automations"},
            {value: "settings", label: "Settings"}
          ]
          
          Tabs(default_value: "invoices") do
            render RubyUI::ResponsiveTabsList.new(
              tabs: tabs_data,
              current_value: "invoices"
            )
            TabsContent(value: "invoices") do
              div(class: "rounded-lg border p-6 space-y-4 bg-background text-foreground") do
                plain "Invoices"
              end
            end
            TabsContent(value: "receipts") do
              div(class: "rounded-lg border p-6 space-y-4 bg-background text-foreground") do
                plain "Receipts"
              end
            end
            TabsContent(value: "customers") do
              div(class: "rounded-lg border p-6 space-y-4 bg-background text-foreground") do
                render Views::Accounting::Customers::Index.new
              end
            end
            TabsContent(value: "items") do
              div(class: "rounded-lg border p-6 space-y-4 bg-background text-foreground") do
                render Views::Accounting::AccountingItems::Index.new
              end
            end
            TabsContent(value: "automations") do
              div(class: "rounded-lg border p-6 space-y-4 bg-background text-foreground") do
                plain "Automations"
              end
            end
            TabsContent(value: "settings") do
              div(class: "rounded-lg border p-6 space-y-4 bg-background text-foreground") do
                render Views::Accounting::Settings::Index.new
              end
            end
          end
        end
      end
    end
  end
end