module Views
  module Accounting
    class Index < Views::Base
      def initialize
      end

      def view_template
        div(class: "flex h-full flex-col") do
          h1(class: "text-2xl font-bold") { "Accounting" }
          Tabs(default_value: "invoices") do
            TabsList do
              TabsTrigger(value: "invoices") { "Invoices" }
              TabsTrigger(value: "receipts") { "Receipts" }
              TabsTrigger(value: "customers") { "Customers" } 
              TabsTrigger(value: "items") { "Items" }
              TabsTrigger(value: "automations") { "Automations" } 
              TabsTrigger(value: "settings") { "Settings" }        
            end
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
                plain "Customers"
              end
            end
            TabsContent(value: "items") do
              div(class: "rounded-lg border p-6 space-y-4 bg-background text-foreground") do
                render Views::Accounting::Settings::AccountingItems::Index.new
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